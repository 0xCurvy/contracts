//@ts-nocheck
/**
 * Execute a SOL bridge from portal vault to Arbitrum.
 *
 * Uses ownerHash + stealthPrivKey (stable outputs from generate-portal-data).
 *
 * Flow:
 *   1. Derive vault PDA from ownerHash + recoveryKey
 *   2. Check vault balance
 *   3. Fetch LiFi quote (SOL → ETH on Arbitrum)
 *   4. Call bridge_relay_sol on the curvy-portal program
 *
 * Usage:
 *   npx tsx scripts/execute-bridge.ts \
 *     --ownerHash <bigint> --recoveryKey <hex> \
 *     [--bridge relaydepository] \
 *     [--cluster mainnet|devnet] \
 *     [--dry-run]
 *
 * Env:
 *   ANCHOR_WALLET — operator keypair (must be the config operator)
 *   RPC_URL       — override RPC endpoint
 */

import anchor from "@coral-xyz/anchor";

const { Program, BN } = anchor;

import { ChainId, createConfig, getQuote } from "@lifi/sdk";
import { secp256k1 } from "@noble/curves/secp256k1.js";
import { Connection, Keypair, LAMPORTS_PER_SOL, PublicKey, SystemProgram, VersionedTransaction } from "@solana/web3.js";
import { createHash } from "crypto";
import { readFileSync } from "fs";
import { createRequire } from "module";
import { resolve } from "path";
import type { CurvyPortal } from "../target/types/curvy_portal.js";

const require = createRequire(import.meta.url);

// ─── Constants ───────────────────────────────────────────────────────────────

const MAINNET_PROGRAM_ID = new PublicKey("6cHtg7sPLL9NQQuuyepnkud6PskMWV5yxvU2vXfag4qX");
const DEVNET_PROGRAM_ID = new PublicKey("HuMaeg6Z81uRhYQ8ct3L3zphbKttULbyhoYGrH1AmLn8");

const PORTAL_SEED = Buffer.from("portal");
const PORTAL_META_SEED = Buffer.from("portal_meta");
const CONFIG_SEED = Buffer.from("config");
const RECOVERY_DOMAIN = Buffer.from("curvy-solana-recovery-v1");

const RELAY_PROGRAM_ID = new PublicKey("99vQwtBwYtrqqD9YSXbdum3KBdxPAVxYTaQ3cfnJSrN2");

const LIFI_SOLANA_CHAIN_ID = 1151111081099710;
const NATIVE_SOL_ADDRESS = "11111111111111111111111111111111";
const NATIVE_ETH_ADDRESS = "0x0000000000000000000000000000000000000000";

const ALLOWED_BRIDGES = ["relaydepository"] as const;
type Bridge = (typeof ALLOWED_BRIDGES)[number];

// ─── Helpers ─────────────────────────────────────────────────────────────────

function toBytes32(input: string): Uint8Array {
  let hexStr: string;
  if (input.startsWith("0x") || input.startsWith("0X")) {
    hexStr = input.slice(2);
  } else if (/^\d+$/.test(input)) {
    hexStr = BigInt(input).toString(16);
  } else {
    hexStr = input;
  }
  return Buffer.from(hexStr.padStart(64, "0").slice(-64), "hex");
}

function deriveRecoveryIdentifier(secpPrivKeyHex: string): PublicKey {
  const privKey = toBytes32(secpPrivKeyHex);
  const compressedPubKey = secp256k1.getPublicKey(privKey, true);
  const hash = createHash("sha256").update(RECOVERY_DOMAIN).update(compressedPubKey).digest();
  return new PublicKey(hash);
}

function loadKeypair(envVar = "ANCHOR_WALLET"): Keypair {
  const walletPath = process.env[envVar] ?? resolve(process.env.HOME!, ".config/solana/id.json");
  const raw = JSON.parse(readFileSync(walletPath, "utf8"));
  return Keypair.fromSecretKey(Uint8Array.from(raw));
}

function explorerTxUrl(sig: string, cluster: string): string {
  const suffix = cluster === "devnet" ? "?cluster=devnet" : "";
  return `https://explorer.solana.com/tx/${sig}${suffix}`;
}

/**
 * Extract the exact Relay deposit and LiFi fee transfers from a quote.
 *
 * Parses the raw V0 message to avoid needing address lookup table resolution.
 * Scans all compiled instructions for one whose program is the relay depository
 * and whose data starts with the deposit_native discriminator.
 *
 * deposit_native instruction data layout:
 *   [0..8]   discriminator: [13, 158, 13, 223, 95, 213, 28, 6]
 *   [8..16]  amount: u64 LE
 *   [16..48] id: [u8; 32]  ← this is the relay_id
 */
function extractRelayQuote(
  quote: any,
  operator: PublicKey,
  grossAmount: bigint,
): {
  relayAmount: bigint;
  relayId: number[];
  feeTransfers: Array<{ recipient: PublicKey; amount: bigint }>;
} {
  const txData = quote.transactionRequest?.data;
  if (!txData) {
    throw new Error("LiFi quote has no transactionRequest.data — cannot extract Relay deposit");
  }

  let txBuffer: Buffer;
  if (typeof txData === "string" && txData.startsWith("0x")) {
    txBuffer = Buffer.from(txData.slice(2), "hex");
  } else if (typeof txData === "string") {
    txBuffer = Buffer.from(txData, "base64");
    if (txBuffer.length === 0) txBuffer = Buffer.from(txData, "hex");
  } else {
    throw new Error("Unexpected transactionRequest.data format");
  }

  const lifiTx = VersionedTransaction.deserialize(txBuffer);
  const msg = lifiTx.message;

  const DEPOSIT_NATIVE_DISC = [13, 158, 13, 223, 95, 213, 28, 6];
  const staticKeys = msg.staticAccountKeys;
  const feeStep = quote.includedSteps?.find((step: any) => step.tool === "feeCollection");
  const expectedFee = feeStep
    ? BigInt(feeStep.action.fromAmount) - BigInt(feeStep.estimate.toAmount)
    : 0n;
  const feeTransfers: Array<{ recipient: PublicKey; amount: bigint }> = [];
  let relayAmount: bigint | undefined;
  let relayId: number[] | undefined;

  for (const cix of msg.compiledInstructions) {
    const programKey = staticKeys[cix.programIdIndex];
    if (programKey?.equals(RELAY_PROGRAM_ID) && cix.data.length >= 48) {
      const discMatch = DEPOSIT_NATIVE_DISC.every((byte, index) => cix.data[index] === byte);
      if (discMatch) {
        relayAmount = Buffer.from(cix.data.slice(8, 16)).readBigUInt64LE();
        relayId = Array.from(cix.data.slice(16, 48));
      }
    }

    if (
      programKey?.equals(SystemProgram.programId) &&
      cix.data.length >= 12 &&
      Buffer.from(cix.data.slice(0, 4)).readUInt32LE() === 2
    ) {
      const sender = staticKeys[cix.accountKeyIndexes[0]];
      const recipient = staticKeys[cix.accountKeyIndexes[1]];
      if (sender?.equals(operator) && recipient) {
        feeTransfers.push({
          recipient,
          amount: Buffer.from(cix.data.slice(4, 12)).readBigUInt64LE(),
        });
      }
    }
  }

  if (relayAmount === undefined || !relayId) {
    throw new Error("Could not find deposit_native instruction in LiFi transaction");
  }
  const actualFee = feeTransfers.reduce((sum, fee) => sum + fee.amount, 0n);
  if (actualFee !== expectedFee || relayAmount + actualFee !== grossAmount) {
    throw new Error(
      `LiFi amount mismatch: gross=${grossAmount}, relay=${relayAmount}, fees=${actualFee}, quotedFees=${expectedFee}`,
    );
  }
  return { relayAmount, relayId, feeTransfers };
}

// ─── Arg parsing ─────────────────────────────────────────────────────────────

function parseArgs(): {
  ownerHash: string;
  recoveryKey: string;
  toAddress: string;
  bridge: Bridge;
  cluster: "mainnet" | "devnet";
  dryRun: boolean;
} {
  const args = process.argv.slice(2);
  let ownerHash: string | undefined;
  let recoveryKey: string | undefined;
  let toAddress: string | undefined;
  let bridge: Bridge = "relaydepository";
  let cluster: "mainnet" | "devnet" = "mainnet";
  let dryRun = false;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--ownerHash" && args[i + 1]) ownerHash = args[++i];
    else if (args[i] === "--recoveryKey" && args[i + 1]) recoveryKey = args[++i];
    else if (args[i] === "--toAddress" && args[i + 1]) toAddress = args[++i];
    else if (args[i] === "--bridge" && args[i + 1]) {
      const b = args[++i] as Bridge;
      if (!ALLOWED_BRIDGES.includes(b)) {
        console.error(`Invalid bridge: ${b}. Must be: ${ALLOWED_BRIDGES.join(", ")}`);
        process.exit(1);
      }
      bridge = b;
    } else if (args[i] === "--cluster" && args[i + 1]) {
      const c = args[++i];
      if (c !== "mainnet" && c !== "devnet") {
        console.error("Invalid cluster. Must be: mainnet, devnet");
        process.exit(1);
      }
      cluster = c;
    } else if (args[i] === "--dry-run") {
      dryRun = true;
    }
  }

  if (!ownerHash || !recoveryKey || !toAddress) {
    console.error(
      "Usage: npx tsx scripts/execute-bridge.ts --ownerHash <bigint> --recoveryKey <hex> --toAddress <0xEvmAddress> [--bridge relaydepository] [--cluster mainnet|devnet] [--dry-run]\n\n" +
        "Get ownerHash and recoveryKey from: yarn generate-portal-data --s <s> --v <v>",
    );
    process.exit(1);
  }

  return { ownerHash, recoveryKey, toAddress, bridge, cluster, dryRun };
}

// ─── Main ────────────────────────────────────────────────────────────────────

async function main() {
  const { ownerHash, recoveryKey, toAddress, bridge, cluster, dryRun } = parseArgs();

  const programId = cluster === "mainnet" ? MAINNET_PROGRAM_ID : DEVNET_PROGRAM_ID;
  const defaultRpc = cluster === "mainnet" ? "https://api.mainnet-beta.solana.com" : "https://api.devnet.solana.com";
  const connection = new Connection(process.env.RPC_URL ?? defaultRpc, "confirmed");

  const operator = loadKeypair();

  console.log(`Cluster:   ${cluster}`);
  console.log(`Bridge:    ${bridge}`);
  console.log(`Program:   ${programId.toBase58()}`);
  console.log(`Operator:  ${operator.publicKey.toBase58()}`);
  if (dryRun) console.log(`Mode:      DRY RUN (no transaction submitted)`);

  // ── 1. Derive vault PDA from stable inputs ─────────────────────────────
  const ownerHashBytes = toBytes32(ownerHash);
  const recoveryIdentifier = deriveRecoveryIdentifier(recoveryKey);

  const [vaultPda] = PublicKey.findProgramAddressSync(
    [PORTAL_SEED, ownerHashBytes, recoveryIdentifier.toBuffer()],
    programId,
  );
  const [metaPda] = PublicKey.findProgramAddressSync(
    [PORTAL_META_SEED, ownerHashBytes, recoveryIdentifier.toBuffer()],
    programId,
  );
  const [configPda] = PublicKey.findProgramAddressSync([CONFIG_SEED], programId);

  console.log(`ownerHash: ${ownerHash}`);
  console.log(`vault PDA: ${vaultPda.toBase58()}`);

  // ── 2. Check vault balance ─────────────────────────────────────────────
  const vaultLamports = await connection.getBalance(vaultPda);
  const vaultSol = vaultLamports / LAMPORTS_PER_SOL;
  console.log(`\nVault balance: ${vaultSol} SOL (${vaultLamports} lamports)`);

  if (vaultLamports === 0) {
    console.error("Vault is empty — nothing to bridge.");
    process.exit(1);
  }

  const rentExempt = await connection.getMinimumBalanceForRentExemption(0);
  const bridgeableLamports = vaultLamports - rentExempt;
  if (bridgeableLamports <= 0) {
    console.error(`Vault only has rent-exempt minimum. Nothing to bridge.`);
    process.exit(1);
  }
  console.log(`Bridgeable: ${bridgeableLamports / LAMPORTS_PER_SOL} SOL (after ${rentExempt} lamport rent reserve)`);

  // ── 3. Get LiFi quote ─────────────────────────────────────────────────
  console.log(`\n--- Fetching LiFi quote (SOL → ETH via ${bridge}) ---`);

  createConfig({ integrator: "curvy-solana-test" });

  const quote = await getQuote({
    fromChain: LIFI_SOLANA_CHAIN_ID,
    toChain: ChainId.ARB,
    fromToken: NATIVE_SOL_ADDRESS,
    toToken: NATIVE_ETH_ADDRESS,
    fromAddress: operator.publicKey.toBase58(),
    toAddress,
    fromAmount: bridgeableLamports.toString(),
    slippage: 0.01,
    allowBridges: [bridge],
  });

  const toAmount = quote.estimate?.toAmount;
  const toAmountMin = quote.estimate?.toAmountMin;
  if (toAmount) {
    console.log(`Output:    ~${(Number(toAmount) / 1e18).toFixed(8)} ETH on Arbitrum`);
    if (toAmountMin) console.log(`Min:       ~${(Number(toAmountMin) / 1e18).toFixed(8)} ETH`);
  }

  if (dryRun) {
    console.log("\n=== DRY RUN — stopping before submission ===");
    const dryRunInfo: any = {
      bridge,
      inputLamports: bridgeableLamports,
      outputEstimate: toAmount,
      outputMin: toAmountMin,
    };
    if (bridge === "relaydepository") {
      try {
        const { relayAmount, relayId, feeTransfers } = extractRelayQuote(
          quote,
          operator.publicKey,
          BigInt(bridgeableLamports),
        );
        dryRunInfo.relayId = Buffer.from(relayId).toString("hex");
        dryRunInfo.relayAmount = relayAmount.toString();
        dryRunInfo.feeTransfers = feeTransfers.map((fee) => ({
          recipient: fee.recipient.toBase58(),
          amount: fee.amount.toString(),
        }));
      } catch (e: any) {
        dryRunInfo.relayIdError = e.message;
      }
    }
    console.log(JSON.stringify(dryRunInfo, null, 2));
    return;
  }

  // ── 4. Execute bridge on-chain ─────────────────────────────────────────
  console.log("\n--- Submitting bridge transaction ---");

  const wallet = new anchor.Wallet(operator);
  const provider = new anchor.AnchorProvider(connection, wallet, {
    commitment: "confirmed",
  });
  anchor.setProvider(provider);

  const idl = require("../target/idl/curvy_portal.json");
  const program = new Program<CurvyPortal>(idl, provider);

  const ownerHashArray = Array.from(ownerHashBytes);
  const recoveryIdArray = Array.from(recoveryIdentifier.toBytes());

  const { relayAmount, relayId, feeTransfers } = extractRelayQuote(
    quote,
    operator.publicKey,
    BigInt(bridgeableLamports),
  );

  const [relayDepo] = PublicKey.findProgramAddressSync([Buffer.from("relay_depository")], RELAY_PROGRAM_ID);
  const [relayVault] = PublicKey.findProgramAddressSync([Buffer.from("vault")], RELAY_PROGRAM_ID);

  console.log(`Relay ID:  ${Buffer.from(relayId).toString("hex")} (from LiFi quote)`);
  console.log(`Relay amount: ${relayAmount} lamports`);
  console.log(`LiFi fees:    ${feeTransfers.reduce((sum, fee) => sum + fee.amount, 0n)} lamports`);

  const tx = await program.methods
    .bridgeRelaySol(
      ownerHashArray,
      recoveryIdArray,
      new BN(bridgeableLamports),
      new BN(relayAmount.toString()),
      feeTransfers.map((fee) => new BN(fee.amount.toString())),
      relayId,
    )
    .accounts({
      operator: operator.publicKey,
      config: configPda,
      portal: metaPda,
      vault: vaultPda,
      relayProgram: RELAY_PROGRAM_ID,
      relayDepository: relayDepo,
      relayVault: relayVault,
      systemProgram: SystemProgram.programId,
    })
    .remainingAccounts(
      feeTransfers.map((fee) => ({
        pubkey: fee.recipient,
        isSigner: false,
        isWritable: true,
      })),
    )
    .rpc();

  console.log(`\nBridged via Relay!`);
  console.log(explorerTxUrl(tx, cluster));

  const finalBalance = await connection.getBalance(vaultPda);
  console.log(`\nVault balance after: ${finalBalance / LAMPORTS_PER_SOL} SOL`);
}

main().catch((err) => {
  console.error("\nError:", err?.message ?? err);
  if (err?.logs) console.error("Logs:", err.logs.join("\n"));
  process.exit(1);
});
