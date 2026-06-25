//@ts-nocheck
/**
 * Bridge funds from a Solana vault to Arbitrum via Across or Relay on devnet.
 *
 * ownerHash accepts: decimal bigint string (Poseidon output), 0x-hex, or plain hex.
 *
 * Usage:
 *   # Bridge SOL via Across:
 *   npx tsx scripts/bridge-portal-devnet.ts <ownerHash> <secpPrivKey> across-sol <amountLamports> <acrossStateSeed> <recipientEvm> <outputToken> <outputAmount> <fillDeadline>
 *
 *   # Bridge SPL via Across:
 *   npx tsx scripts/bridge-portal-devnet.ts <ownerHash> <secpPrivKey> across-spl <mint> <amountRaw> <acrossStateSeed> <recipientEvm> <outputToken> <outputAmount> <fillDeadline>
 *
 *   # Bridge SOL via Relay:
 *   npx tsx scripts/bridge-portal-devnet.ts <ownerHash> <secpPrivKey> relay-sol <amountLamports> <relayId>
 *
 *   # Bridge SPL via Relay:
 *   npx tsx scripts/bridge-portal-devnet.ts <ownerHash> <secpPrivKey> relay-spl <mint> <amountRaw> <relayId>
 *
 * Env:
 *   ANCHOR_WALLET — operator keypair path (must be the config operator)
 *   RPC_URL       — devnet RPC
 */

import anchor from "@coral-xyz/anchor";
import {
  ASSOCIATED_TOKEN_PROGRAM_ID,
  getAssociatedTokenAddress,
  NATIVE_MINT,
  TOKEN_PROGRAM_ID,
} from "@solana/spl-token";
import { PublicKey, SystemProgram } from "@solana/web3.js";
import { createRequire } from "module";
import type { CurvyPortal } from "../target/types/curvy_portal.js";
import {
  deriveConfigPda,
  derivePortalMetaPda,
  deriveRecoveryIdentifier,
  deriveVaultPda,
  getConnection,
  loadKeypair,
  toBytes32,
  txUrl,
} from "./devnet-helpers.js";

const { Program, BN } = anchor;

const require = createRequire(import.meta.url);

// Across program ID (from IDL)
const ACROSS_PROGRAM_ID = new PublicKey("DLv3NggMiSaef97YCkew5xKUHDh13tVGZ7tydt3ZeAru");

// Relay depository program ID (from IDL)
const RELAY_PROGRAM_ID = new PublicKey("99vQwtBwYtrqqD9YSXbdum3KBdxPAVxYTaQ3cfnJSrN2");

function evmAddressToPubkey(address20Hex: string): PublicKey {
  const hex = address20Hex.replace("0x", "");
  const buf = Buffer.alloc(32, 0);
  Buffer.from(hex, "hex").copy(buf, 12);
  return new PublicKey(buf);
}

function outputAmountBytes32(amount: bigint): number[] {
  const arr = new Array(32).fill(0);
  const beBytes = [];
  let n = amount;
  for (let i = 0; i < 8; i++) {
    beBytes.unshift(Number(n & 0xffn));
    n >>= 8n;
  }
  for (let i = 0; i < 8; i++) arr[24 + i] = beBytes[i];
  return arr;
}

function acrossStatePda(stateSeed: bigint): [PublicKey, number] {
  const seedBuf = Buffer.alloc(8);
  seedBuf.writeBigUInt64LE(stateSeed);
  return PublicKey.findProgramAddressSync([Buffer.from("state"), seedBuf], ACROSS_PROGRAM_ID);
}

function acrossEventAuthorityPda(): [PublicKey, number] {
  return PublicKey.findProgramAddressSync([Buffer.from("__event_authority")], ACROSS_PROGRAM_ID);
}

function relayDepositoryPda(): [PublicKey, number] {
  return PublicKey.findProgramAddressSync([Buffer.from("relay_depository")], RELAY_PROGRAM_ID);
}

function relayVaultPda(): [PublicKey, number] {
  return PublicKey.findProgramAddressSync([Buffer.from("vault")], RELAY_PROGRAM_ID);
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length < 4) {
    console.error(
      "Usage: npx tsx scripts/bridge-portal-devnet.ts <ownerHash> <secpPrivKey> <mode> [args...]\n" +
        "Modes: across-sol, across-spl, relay-sol, relay-spl",
    );
    process.exit(1);
  }

  const [ownerHashArg, privKeyArg, mode, ...rest] = args;

  const connection = getConnection();
  const operator = loadKeypair();
  const wallet = new anchor.Wallet(operator);
  const provider = new anchor.AnchorProvider(connection, wallet, {
    commitment: "confirmed",
  });
  anchor.setProvider(provider);

  const idl = require("../target/idl/curvy_portal.json");
  const program = new Program<CurvyPortal>(idl, provider);

  const ownerHashBytes = toBytes32(ownerHashArg!);
  const { recoveryIdentifier } = deriveRecoveryIdentifier(privKeyArg!);
  const [vaultPda] = deriveVaultPda(ownerHashBytes, recoveryIdentifier);
  const [metaPda] = derivePortalMetaPda(ownerHashBytes, recoveryIdentifier);
  const [configPda] = deriveConfigPda();

  const ownerHash = Array.from(ownerHashBytes);
  const recoveryIdArray = Array.from(recoveryIdentifier.toBytes());

  console.log(`Operator:  ${operator.publicKey.toBase58()}`);
  console.log(`Vault PDA: ${vaultPda.toBase58()}`);

  if (mode === "across-sol") {
    // across-sol <amountLamports> <stateSeed> <recipientEvm> <outputToken> <outputAmount> <fillDeadline>
    const [amountStr, stateSeedStr, recipientEvmHex, outputTokenHex, outputAmountStr, fillDeadlineStr] = rest;
    if (!amountStr || !stateSeedStr || !recipientEvmHex || !outputTokenHex || !outputAmountStr || !fillDeadlineStr) {
      console.error(
        "across-sol requires: <amountLamports> <stateSeed> <recipientEvm> <outputToken> <outputAmount> <fillDeadline>",
      );
      process.exit(1);
    }

    const inputAmount = BigInt(amountStr);
    const stateSeed = BigInt(stateSeedStr);
    const fillDeadline = parseInt(fillDeadlineStr);
    const now = Math.floor(Date.now() / 1000);

    const recipient = evmAddressToPubkey(recipientEvmHex);
    const outputToken = evmAddressToPubkey(outputTokenHex);
    const outputAmount = outputAmountBytes32(BigInt(outputAmountStr));

    const [acrossState] = acrossStatePda(stateSeed);
    const [acrossEventAuth] = acrossEventAuthorityPda();
    const vaultWsolAta = await getAssociatedTokenAddress(NATIVE_MINT, vaultPda, true);
    const acrossVault = await getAssociatedTokenAddress(NATIVE_MINT, acrossState, true);

    // The delegate account — Across uses a PDA as the delegate
    // This is derived from the Across state. For real usage, get from the quote.
    const acrossDelegate = acrossState; // Placeholder — replace with actual delegate from quote

    console.log(`\n--- bridge_sol (Across) ---`);
    console.log(`Amount:     ${inputAmount} lamports`);
    console.log(`Recipient:  ${recipientEvmHex}`);
    console.log(`Fill deadline: ${fillDeadline}`);

    const tx = await program.methods
      .bridgeSol(ownerHash, recoveryIdArray, new BN(inputAmount.toString()), new BN(stateSeed.toString()), {
        recipient,
        outputToken,
        outputAmount,
        destinationChainId: new BN(42161),
        exclusiveRelayer: PublicKey.default,
        quoteTimestamp: now,
        fillDeadline,
        exclusivityParameter: 0,
        message: Buffer.from([]),
      })
      .accounts({
        operator: operator.publicKey,
        config: configPda,
        portal: metaPda,
        vault: vaultPda,
        vaultWsolAta,
        wsolMint: NATIVE_MINT,
        acrossProgram: ACROSS_PROGRAM_ID,
        acrossState,
        acrossDelegate,
        acrossVault,
        acrossEventAuthority: acrossEventAuth,
        tokenProgram: TOKEN_PROGRAM_ID,
        associatedTokenProgram: ASSOCIATED_TOKEN_PROGRAM_ID,
        systemProgram: SystemProgram.programId,
      })
      .rpc();

    console.log(`\nBridged! ${txUrl(tx)}`);
  } else if (mode === "across-spl") {
    // across-spl <mint> <amountRaw> <stateSeed> <recipientEvm> <outputToken> <outputAmount> <fillDeadline>
    const [mintStr, amountStr, stateSeedStr, recipientEvmHex, outputTokenHex, outputAmountStr, fillDeadlineStr] = rest;
    if (
      !mintStr ||
      !amountStr ||
      !stateSeedStr ||
      !recipientEvmHex ||
      !outputTokenHex ||
      !outputAmountStr ||
      !fillDeadlineStr
    ) {
      console.error(
        "across-spl requires: <mint> <amountRaw> <stateSeed> <recipientEvm> <outputToken> <outputAmount> <fillDeadline>",
      );
      process.exit(1);
    }

    const mint = new PublicKey(mintStr);
    const inputAmount = BigInt(amountStr);
    const stateSeed = BigInt(stateSeedStr);
    const fillDeadline = parseInt(fillDeadlineStr);
    const now = Math.floor(Date.now() / 1000);

    const recipient = evmAddressToPubkey(recipientEvmHex);
    const outputToken = evmAddressToPubkey(outputTokenHex);
    const outputAmount = outputAmountBytes32(BigInt(outputAmountStr));

    const [acrossState] = acrossStatePda(stateSeed);
    const [acrossEventAuth] = acrossEventAuthorityPda();
    const vaultTokenAccount = await getAssociatedTokenAddress(mint, vaultPda, true);
    const acrossVault = await getAssociatedTokenAddress(mint, acrossState, true);
    const acrossDelegate = acrossState;

    console.log(`\n--- bridge_spl (Across) ---`);
    console.log(`Mint:       ${mint.toBase58()}`);
    console.log(`Amount:     ${inputAmount}`);
    console.log(`Recipient:  ${recipientEvmHex}`);

    const tx = await program.methods
      .bridgeSpl(ownerHash, recoveryIdArray, new BN(inputAmount.toString()), new BN(stateSeed.toString()), {
        recipient,
        outputToken,
        outputAmount,
        destinationChainId: new BN(42161),
        exclusiveRelayer: PublicKey.default,
        quoteTimestamp: now,
        fillDeadline,
        exclusivityParameter: 0,
        message: Buffer.from([]),
      })
      .accounts({
        operator: operator.publicKey,
        config: configPda,
        portal: metaPda,
        vault: vaultPda,
        vaultTokenAccount,
        mint,
        acrossProgram: ACROSS_PROGRAM_ID,
        acrossState,
        acrossDelegate,
        acrossVault,
        acrossEventAuthority: acrossEventAuth,
        tokenProgram: TOKEN_PROGRAM_ID,
        associatedTokenProgram: ASSOCIATED_TOKEN_PROGRAM_ID,
        systemProgram: SystemProgram.programId,
      })
      .rpc();

    console.log(`\nBridged! ${txUrl(tx)}`);
  } else if (mode === "relay-sol") {
    // relay-sol <amountLamports> <relayId>
    const [amountStr, relayIdHex] = rest;
    if (!amountStr || !relayIdHex) {
      console.error("relay-sol requires: <amountLamports> <relayId hex>");
      process.exit(1);
    }

    const inputAmount = BigInt(amountStr);
    const relayId = Array.from(toBytes32(relayIdHex));
    const [relayDepo] = relayDepositoryPda();
    const [relayVault] = relayVaultPda();

    console.log(`\n--- bridge_relay_sol ---`);
    console.log(`Amount: ${inputAmount} lamports`);
    console.log(`Relay ID: ${relayIdHex}`);

    const tx = await program.methods
      .bridgeRelaySol(ownerHash, recoveryIdArray, new BN(inputAmount.toString()), relayId)
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
      .rpc();

    console.log(`\nBridged via Relay! ${txUrl(tx)}`);
  } else if (mode === "relay-spl") {
    // relay-spl <mint> <amountRaw> <relayId>
    const [mintStr, amountStr, relayIdHex] = rest;
    if (!mintStr || !amountStr || !relayIdHex) {
      console.error("relay-spl requires: <mint> <amountRaw> <relayId hex>");
      process.exit(1);
    }

    const mint = new PublicKey(mintStr);
    const inputAmount = BigInt(amountStr);
    const relayId = Array.from(toBytes32(relayIdHex));
    const [relayDepo] = relayDepositoryPda();
    const [relayVault] = relayVaultPda();
    const vaultTokenAccount = await getAssociatedTokenAddress(mint, vaultPda, true);
    const relayVaultTokenAccount = await getAssociatedTokenAddress(mint, relayVault, true);

    console.log(`\n--- bridge_relay_spl ---`);
    console.log(`Mint:     ${mint.toBase58()}`);
    console.log(`Amount:   ${inputAmount}`);
    console.log(`Relay ID: ${relayIdHex}`);

    const tx = await program.methods
      .bridgeRelaySpl(ownerHash, recoveryIdArray, new BN(inputAmount.toString()), relayId)
      .accounts({
        operator: operator.publicKey,
        config: configPda,
        portal: metaPda,
        vault: vaultPda,
        vaultTokenAccount,
        mint,
        relayProgram: RELAY_PROGRAM_ID,
        relayDepository: relayDepo,
        relayVault: relayVault,
        relayVaultTokenAccount,
        tokenProgram: TOKEN_PROGRAM_ID,
        associatedTokenProgram: ASSOCIATED_TOKEN_PROGRAM_ID,
        systemProgram: SystemProgram.programId,
      })
      .rpc();

    console.log(`\nBridged via Relay! ${txUrl(tx)}`);
  } else {
    console.error(`Unknown mode: ${mode}`);
    console.error("Modes: across-sol, across-spl, relay-sol, relay-spl");
    process.exit(1);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
