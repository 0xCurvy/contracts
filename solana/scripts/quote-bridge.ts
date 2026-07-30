/**
 * Get a LiFi quote for bridging SOL from a portal vault to ETH on Arbitrum.
 *
 * Uses ownerHash + stealthPrivKey (stable outputs from generate-portal-data).
 * These are deterministic for a given portal — unlike s/v which produce
 * a new ephemeral key on every core.send() call.
 *
 * Usage:
 *   npx tsx scripts/quote-bridge.ts --ownerHash <bigint> --recoveryKey <hex>
 *   npx tsx scripts/quote-bridge.ts --ownerHash <bigint> --recoveryKey <hex> --bridge relaydepository
 *
 * Options:
 *   --bridge <relaydepository>          LiFi bridge to use
 *   --fromAddress <operator pubkey>     On-curve transaction signer used for the quote
 *   --cluster <mainnet|devnet>          Network (default: mainnet)
 *
 * Env:
 *   RPC_URL — override RPC endpoint
 */

import { ChainId, createConfig, getQuote } from "@lifi/sdk";
import { secp256k1 } from "@noble/curves/secp256k1.js";
import { Connection, PublicKey } from "@solana/web3.js";
import { createHash } from "crypto";

// ─── Constants ───────────────────────────────────────────────────────────────

const MAINNET_PROGRAM_ID = new PublicKey("6cHtg7sPLL9NQQuuyepnkud6PskMWV5yxvU2vXfag4qX");
const DEVNET_PROGRAM_ID = new PublicKey("HuMaeg6Z81uRhYQ8ct3L3zphbKttULbyhoYGrH1AmLn8");

const PORTAL_SEED = Buffer.from("portal");
const RECOVERY_DOMAIN = Buffer.from("curvy-solana-recovery-v1");

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

// ─── Arg parsing ─────────────────────────────────────────────────────────────

function parseArgs(): {
  ownerHash: string;
  recoveryKey: string;
  fromAddress: string;
  toAddress: string;
  bridge: Bridge;
  cluster: "mainnet" | "devnet";
} {
  const args = process.argv.slice(2);
  let ownerHash: string | undefined;
  let recoveryKey: string | undefined;
  let fromAddress = process.env.OPERATOR_ADDRESS;
  let toAddress: string | undefined;
  let bridge: Bridge = "relaydepository";
  let cluster: "mainnet" | "devnet" = "mainnet";

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--ownerHash" && args[i + 1]) ownerHash = args[++i];
    else if (args[i] === "--recoveryKey" && args[i + 1]) recoveryKey = args[++i];
    else if (args[i] === "--fromAddress" && args[i + 1]) fromAddress = args[++i];
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
    }
  }

  if (!ownerHash || !recoveryKey || !fromAddress || !toAddress) {
    console.error(
      "Usage: npx tsx scripts/quote-bridge.ts --ownerHash <bigint> --recoveryKey <hex> --fromAddress <operatorPubkey> --toAddress <0xEvmAddress> [--bridge relaydepository] [--cluster mainnet|devnet]\n\n" +
        "Get ownerHash and recoveryKey from: yarn generate-portal-data --s <s> --v <v>",
    );
    process.exit(1);
  }

  return { ownerHash, recoveryKey, fromAddress, toAddress, bridge, cluster };
}

// ─── Main ────────────────────────────────────────────────────────────────────

async function main() {
  const { ownerHash, recoveryKey, fromAddress, toAddress, bridge, cluster } = parseArgs();

  const programId = cluster === "mainnet" ? MAINNET_PROGRAM_ID : DEVNET_PROGRAM_ID;
  const defaultRpc = cluster === "mainnet" ? "https://api.mainnet-beta.solana.com" : "https://api.devnet.solana.com";
  const connection = new Connection(process.env.RPC_URL ?? defaultRpc, "confirmed");

  console.log(`Cluster:  ${cluster}`);
  console.log(`Bridge:   ${bridge}`);
  console.log(`Program:  ${programId.toBase58()}`);

  // ── 1. Derive vault PDA from stable inputs ────────────────────────────
  const ownerHashBytes = toBytes32(ownerHash);
  const recoveryIdentifier = deriveRecoveryIdentifier(recoveryKey);

  const [vaultPda] = PublicKey.findProgramAddressSync(
    [PORTAL_SEED, ownerHashBytes, recoveryIdentifier.toBuffer()],
    programId,
  );

  console.log(`ownerHash:  ${ownerHash}`);
  console.log(`recoveryId: ${recoveryIdentifier.toBase58()}`);
  console.log(`vault PDA:  ${vaultPda.toBase58()}`);

  // ── 2. Check vault balance ─────────────────────────────────────────────
  const vaultLamports = await connection.getBalance(vaultPda);
  const vaultSol = vaultLamports / 1e9;

  console.log(`\n--- Vault Balance ---`);
  console.log(`${vaultSol} SOL (${vaultLamports} lamports)`);

  if (vaultLamports === 0) {
    console.error(
      `\nVault is empty — nothing to bridge.\nFund it first: solana transfer ${vaultPda.toBase58()} <amount> --url ${
        cluster === "mainnet" ? "mainnet-beta" : "devnet"
      }`,
    );
    process.exit(1);
  }

  // ── 3. Get LiFi quote ─────────────────────────────────────────────────
  console.log(`\n--- Fetching LiFi quote (SOL → ETH via ${bridge}) ---`);

  createConfig({ integrator: "curvy-solana-test" });

  const quote = await getQuote({
    fromChain: LIFI_SOLANA_CHAIN_ID,
    toChain: ChainId.ARB,
    fromToken: NATIVE_SOL_ADDRESS,
    toToken: NATIVE_ETH_ADDRESS,
    // The vault is a PDA and cannot satisfy LiFi's signer/rent simulation.
    // The Curvy program maps this on-curve identity back to the PDA sender.
    fromAddress,
    toAddress,
    fromAmount: vaultLamports.toString(),
    slippage: 0.01,
    allowBridges: [bridge],
  });

  // ── 4. Print quote summary ─────────────────────────────────────────────
  console.log("\n=== LiFi Quote ===");
  console.log(`Bridge:           ${quote.toolDetails?.name ?? quote.tool}`);
  console.log(`From:             ${vaultSol} SOL (Solana)`);

  const toAmount = quote.estimate?.toAmount;
  const toAmountMin = quote.estimate?.toAmountMin;
  if (toAmount) {
    const ethAmount = Number(toAmount) / 1e18;
    const ethAmountMin = toAmountMin ? Number(toAmountMin) / 1e18 : ethAmount;
    console.log(`To (estimated):   ${ethAmount.toFixed(8)} ETH (Arbitrum)`);
    console.log(`To (min):         ${ethAmountMin.toFixed(8)} ETH`);
  }

  const duration = quote.estimate?.executionDuration;
  if (duration) {
    const mins = Math.ceil(duration / 60);
    console.log(`Est. time:        ~${mins} min (${duration}s)`);
  }

  const feeCosts = quote.estimate?.feeCosts;
  if (feeCosts && feeCosts.length > 0) {
    console.log(`\n--- Fees ---`);
    for (const fee of feeCosts) {
      const amt = fee.amount ? Number(fee.amount) / 10 ** (fee.token?.decimals ?? 9) : 0;
      console.log(`  ${fee.name}: ${amt.toFixed(6)} ${fee.token?.symbol ?? ""} ($${fee.amountUSD ?? "?"})`);
    }
  }

  const gasCosts = quote.estimate?.gasCosts;
  if (gasCosts && gasCosts.length > 0) {
    console.log(`\n--- Gas ---`);
    for (const gas of gasCosts) {
      const amt = gas.amount ? Number(gas.amount) / 10 ** (gas.token?.decimals ?? 9) : 0;
      console.log(`  ${gas.type}: ${amt.toFixed(6)} ${gas.token?.symbol ?? ""} ($${gas.amountUSD ?? "?"})`);
    }
  }

  const txData = (quote as any).transactionRequest?.data;
  if (txData) {
    console.log(`\nTransaction data: ${txData.slice(0, 40)}... (${txData.length} chars)`);
  }

  // ── Ready-to-use execute command ───────────────────────────────────────
  console.log("\n=== Execute ===");
  console.log(
    `yarn execute-bridge --ownerHash ${ownerHash} --recoveryKey ${recoveryKey} --bridge ${bridge} --cluster ${cluster}`,
  );
}

main().catch((err) => {
  console.error("\nError:", err?.message ?? err);
  if (err?.response?.data) {
    console.error("LiFi API error:", JSON.stringify(err.response.data, null, 2));
  }
  process.exit(1);
});
