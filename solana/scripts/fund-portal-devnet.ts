//@ts-nocheck
/**
 * Create vault PDA and fund it with SOL or SPL tokens on devnet.
 *
 * Usage:
 *   # Fund with SOL (amount in SOL):
 *   npx tsx scripts/fund-portal-devnet.ts <ownerHash> <secpPrivKey> sol <amount>
 *
 *   # Fund with SPL (amount in raw token units):
 *   npx tsx scripts/fund-portal-devnet.ts <ownerHash> <secpPrivKey> spl <mint> <amount>
 *
 * ownerHash accepts: decimal bigint string (Poseidon output), 0x-hex, or plain hex.
 *
 * Examples:
 *   npx tsx scripts/fund-portal-devnet.ts 702705117071108858750548073842146797693190729490869702449519502701872077655 0xdead...1234 sol 0.5
 *   npx tsx scripts/fund-portal-devnet.ts 702705117071108858750548073842146797693190729490869702449519502701872077655 0xdead...1234 spl EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v 1000000
 *
 * Env:
 *   ANCHOR_WALLET — operator keypair path (must be the config operator)
 *   RPC_URL       — devnet RPC
 */

import anchor from "@coral-xyz/anchor";

const { Program } = anchor;

import {
  ASSOCIATED_TOKEN_PROGRAM_ID,
  getAccount,
  getAssociatedTokenAddress,
  TOKEN_PROGRAM_ID,
} from "@solana/spl-token";
import { LAMPORTS_PER_SOL, PublicKey, SystemProgram, Transaction } from "@solana/web3.js";
import { createRequire } from "module";
import type { CurvyPortal } from "../target/types/curvy_portal.js";

const require = createRequire(import.meta.url);

import {
  deriveConfigPda,
  deriveRecoveryIdentifier,
  deriveVaultPda,
  explorerUrl,
  getConnection,
  loadKeypair,
  toBytes32,
  txUrl,
} from "./devnet-helpers.js";

async function main() {
  const args = process.argv.slice(2);

  if (args.length < 4) {
    console.error(
      "Usage:\n" +
        "  npx tsx scripts/fund-portal-devnet.ts <ownerHash> <secpPrivKey> sol <amountSOL>\n" +
        "  npx tsx scripts/fund-portal-devnet.ts <ownerHash> <secpPrivKey> spl <mint> <amountRaw>",
    );
    process.exit(1);
  }

  const [ownerHashArg, privKeyArg, mode, ...rest] = args;
  const connection = getConnection();
  const operator = loadKeypair();

  console.log(`Operator: ${operator.publicKey.toBase58()}`);
  console.log(`Balance:  ${(await connection.getBalance(operator.publicKey)) / LAMPORTS_PER_SOL} SOL`);

  // Setup Anchor provider manually for devnet
  const wallet = new anchor.Wallet(operator);
  const provider = new anchor.AnchorProvider(connection, wallet, {
    commitment: "confirmed",
  });
  anchor.setProvider(provider);

  const idl = require("../target/idl/curvy_portal.json");
  const program = new Program<CurvyPortal>(idl, provider);

  const ownerHashBytes = toBytes32(ownerHashArg!);
  const { recoveryIdentifier } = deriveRecoveryIdentifier(privKeyArg!);
  const [vaultPda, vaultBump] = deriveVaultPda(ownerHashBytes, recoveryIdentifier);
  const [configPda] = deriveConfigPda();

  const ownerHash = Array.from(ownerHashBytes);
  const recoveryIdArray = Array.from(recoveryIdentifier.toBytes());

  console.log(`\nVault PDA: ${vaultPda.toBase58()}`);
  console.log(`Recovery:  ${recoveryIdentifier.toBase58()}`);

  if (mode === "sol") {
    const amountSol = parseFloat(rest[0]!);
    if (isNaN(amountSol) || amountSol <= 0) {
      console.error("Invalid SOL amount");
      process.exit(1);
    }
    const lamports = Math.floor(amountSol * LAMPORTS_PER_SOL);

    // Step 1: Create vault PDA
    console.log("\n--- Step 1: create_stealth_sol ---");
    try {
      const tx1 = await program.methods
        .createStealthSol(ownerHash, recoveryIdArray)
        .accounts({
          operator: operator.publicKey,
          config: configPda,
          vault: vaultPda,
          systemProgram: SystemProgram.programId,
        })
        .rpc();
      console.log(`Vault created: ${txUrl(tx1)}`);
    } catch (err: any) {
      if (err.toString().includes("already in use")) {
        console.log("Vault already exists, skipping creation.");
      } else {
        throw err;
      }
    }

    // Step 2: Transfer SOL
    console.log(`\n--- Step 2: Transfer ${amountSol} SOL to vault ---`);
    const transferIx = SystemProgram.transfer({
      fromPubkey: operator.publicKey,
      toPubkey: vaultPda,
      lamports,
    });
    const tx2 = await provider.sendAndConfirm(new Transaction().add(transferIx));
    console.log(`Funded: ${txUrl(tx2)}`);

    // Check balance
    const balance = await connection.getBalance(vaultPda);
    console.log(`\nVault balance: ${balance / LAMPORTS_PER_SOL} SOL`);
    console.log(`Explorer: ${explorerUrl(vaultPda.toBase58())}`);
  } else if (mode === "spl") {
    const [mintArg, amountArg] = rest;
    if (!mintArg || !amountArg) {
      console.error("SPL mode requires: <mint> <amountRaw>");
      process.exit(1);
    }
    const mint = new PublicKey(mintArg);
    const amount = BigInt(amountArg);

    const vaultAta = await getAssociatedTokenAddress(mint, vaultPda, true);

    // Step 1: Create vault + ATA
    console.log("\n--- Step 1: create_stealth_spl_ata ---");
    try {
      const tx1 = await program.methods
        .createStealthSplAta(ownerHash, recoveryIdArray)
        .accounts({
          operator: operator.publicKey,
          config: configPda,
          vault: vaultPda,
          mint,
          vaultTokenAccount: vaultAta,
          tokenProgram: TOKEN_PROGRAM_ID,
          associatedTokenProgram: ASSOCIATED_TOKEN_PROGRAM_ID,
          systemProgram: SystemProgram.programId,
        })
        .rpc();
      console.log(`Vault + ATA created: ${txUrl(tx1)}`);
    } catch (err: any) {
      if (err.toString().includes("already in use")) {
        console.log("Vault/ATA already exists, skipping creation.");
      } else {
        throw err;
      }
    }

    // Step 2: Transfer SPL tokens from operator's ATA to vault ATA
    console.log(`\n--- Step 2: Transfer ${amount} tokens to vault ATA ---`);
    const operatorAta = await getAssociatedTokenAddress(mint, operator.publicKey);

    // Check operator has enough
    try {
      const operatorAccount = await getAccount(connection, operatorAta);
      console.log(`Operator token balance: ${operatorAccount.amount}`);
      if (operatorAccount.amount < amount) {
        console.error(`Insufficient tokens. Have ${operatorAccount.amount}, need ${amount}`);
        process.exit(1);
      }
    } catch {
      console.error(`Operator ATA not found for mint ${mint.toBase58()}`);
      console.error(`Create one first: spl-token create-account ${mint.toBase58()}`);
      process.exit(1);
    }

    const { createTransferInstruction } = await import("@solana/spl-token");
    const transferIx = createTransferInstruction(operatorAta, vaultAta, operator.publicKey, amount);
    const tx2 = await provider.sendAndConfirm(new Transaction().add(transferIx));
    console.log(`Funded: ${txUrl(tx2)}`);

    // Check balance
    const vaultAccount = await getAccount(connection, vaultAta);
    console.log(`\nVault token balance: ${vaultAccount.amount}`);
    console.log(`Vault ATA: ${explorerUrl(vaultAta.toBase58())}`);
  } else {
    console.error(`Unknown mode: ${mode}. Use "sol" or "spl".`);
    process.exit(1);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
