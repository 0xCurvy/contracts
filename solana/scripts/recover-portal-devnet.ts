//@ts-nocheck
/**
 * Recover SOL or SPL tokens from a vault PDA using secp256k1 signature on devnet.
 *
 * ownerHash accepts: decimal bigint string (Poseidon output), 0x-hex, or plain hex.
 *
 * Usage:
 *   # Recover SOL:
 *   npx tsx scripts/recover-portal-devnet.ts <ownerHash> <secpPrivKey> sol <recipientPubkey>
 *
 *   # Recover SPL:
 *   npx tsx scripts/recover-portal-devnet.ts <ownerHash> <secpPrivKey> spl <mint> <recipientPubkey>
 *
 * Examples:
 *   npx tsx scripts/recover-portal-devnet.ts \
 *     702705117071108858750548073842146797693190729490869702449519502701872077655 \
 *     0xdead...1234 sol 7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU
 *
 *   npx tsx scripts/recover-portal-devnet.ts \
 *     702705117071108858750548073842146797693190729490869702449519502701872077655 \
 *     0xdead...1234 spl EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v 7xKXtg...AsU
 *
 * Env:
 *   ANCHOR_WALLET — payer keypair (anyone can submit, doesn't need to be operator)
 *   RPC_URL       — devnet RPC
 */

import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import {
  ASSOCIATED_TOKEN_PROGRAM_ID,
  getAccount,
  getAssociatedTokenAddress,
  getOrCreateAssociatedTokenAccount,
  TOKEN_PROGRAM_ID,
} from "@solana/spl-token";
import { LAMPORTS_PER_SOL, PublicKey, SystemProgram } from "@solana/web3.js";
import { createRequire } from "module";
import type { CurvyPortal } from "../target/types/curvy_portal.js";
import {
  DEVNET_PROGRAM_ID,
  derivePortalMetaPda,
  deriveRecoveryIdentifier,
  deriveVaultPda,
  getConnection,
  loadKeypair,
  signSolRecovery,
  signSplRecovery,
  toBytes32,
  txUrl,
} from "./devnet-helpers.js";

const require = createRequire(import.meta.url);
async function main() {
  const args = process.argv.slice(2);

  if (args.length < 4) {
    console.error(
      "Usage:\n" +
        "  npx tsx scripts/recover-portal-devnet.ts <ownerHash> <secpPrivKey> sol <recipientPubkey>\n" +
        "  npx tsx scripts/recover-portal-devnet.ts <ownerHash> <secpPrivKey> spl <mint> <recipientPubkey>",
    );
    process.exit(1);
  }

  const [ownerHashArg, privKeyArg, mode, ...rest] = args;

  const connection = getConnection();
  const payer = loadKeypair();
  const wallet = new anchor.Wallet(payer);
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

  const ownerHash = Array.from(ownerHashBytes);
  const recoveryIdArray = Array.from(recoveryIdentifier.toBytes());

  console.log(`Payer:     ${payer.publicKey.toBase58()}`);
  console.log(`Vault PDA: ${vaultPda.toBase58()}`);
  console.log(`Recovery:  ${recoveryIdentifier.toBase58()}`);

  if (mode === "sol") {
    const [recipientStr] = rest;
    if (!recipientStr) {
      console.error("sol mode requires: <recipientPubkey>");
      process.exit(1);
    }
    const recipient = new PublicKey(recipientStr);

    // Check vault balance
    const vaultBalance = await connection.getBalance(vaultPda);
    console.log(`\nVault balance: ${vaultBalance / LAMPORTS_PER_SOL} SOL`);

    if (vaultBalance === 0) {
      console.error("Vault is empty — nothing to recover.");
      process.exit(1);
    }

    // Sign recovery message with secp256k1 key
    console.log(`\n--- Signing recovery for recipient: ${recipient.toBase58()} ---`);
    const { signature, recoveryId } = signSolRecovery(
      privKeyArg!,
      DEVNET_PROGRAM_ID,
      ownerHashBytes,
      recoveryIdentifier,
      recipient,
    );

    console.log(`Recovery ID: ${recoveryId}`);
    console.log(`Signature:   ${Buffer.from(signature).toString("hex").slice(0, 32)}...`);

    // Submit recovery transaction
    console.log(`\n--- Submitting recover_sol ---`);
    const tx = await program.methods
      .recoverSol(ownerHash, recoveryIdArray, recoveryId, signature)
      .accounts({
        payer: payer.publicKey,
        vault: vaultPda,
        recipient,
        portalMeta: metaPda,
        systemProgram: SystemProgram.programId,
      })
      .rpc();

    console.log(`\nRecovered! ${txUrl(tx)}`);

    // Check final balances
    const recipientBalance = await connection.getBalance(recipient);
    const vaultFinal = await connection.getBalance(vaultPda);
    console.log(`\nRecipient balance: ${recipientBalance / LAMPORTS_PER_SOL} SOL`);
    console.log(`Vault balance:     ${vaultFinal / LAMPORTS_PER_SOL} SOL`);
  } else if (mode === "spl") {
    const [mintStr, recipientStr] = rest;
    if (!mintStr || !recipientStr) {
      console.error("spl mode requires: <mint> <recipientPubkey>");
      process.exit(1);
    }
    const mint = new PublicKey(mintStr);
    const recipient = new PublicKey(recipientStr);

    const vaultAta = await getAssociatedTokenAddress(mint, vaultPda, true);

    // Check vault token balance
    let vaultBalance: bigint;
    try {
      const vaultAccount = await getAccount(connection, vaultAta);
      vaultBalance = vaultAccount.amount;
      console.log(`\nVault token balance: ${vaultBalance}`);
    } catch {
      console.error("Vault ATA not found — no tokens to recover.");
      process.exit(1);
    }

    if (vaultBalance === 0n) {
      console.error("Vault token balance is 0 — nothing to recover.");
      process.exit(1);
    }

    // Ensure recipient ATA exists
    console.log(`\nEnsuring recipient ATA exists...`);
    const recipientAtaAccount = await getOrCreateAssociatedTokenAccount(connection, payer, mint, recipient);
    console.log(`Recipient ATA: ${recipientAtaAccount.address.toBase58()}`);

    // Sign recovery message
    console.log(`\n--- Signing SPL recovery for recipient: ${recipient.toBase58()} ---`);
    const { signature, recoveryId } = signSplRecovery(
      privKeyArg!,
      DEVNET_PROGRAM_ID,
      ownerHashBytes,
      recoveryIdentifier,
      recipient,
      mint,
    );

    console.log(`Recovery ID: ${recoveryId}`);
    console.log(`Signature:   ${Buffer.from(signature).toString("hex").slice(0, 32)}...`);

    // Submit recovery
    console.log(`\n--- Submitting recover_spl ---`);
    const tx = await program.methods
      .recoverSpl(ownerHash, recoveryIdArray, recoveryId, signature)
      .accounts({
        payer: payer.publicKey,
        vault: vaultPda,
        vaultTokenAccount: vaultAta,
        recipientTokenAccount: recipientAtaAccount.address,
        recipient,
        mint,
        portalMeta: metaPda,
        tokenProgram: TOKEN_PROGRAM_ID,
        associatedTokenProgram: ASSOCIATED_TOKEN_PROGRAM_ID,
        systemProgram: SystemProgram.programId,
      })
      .rpc();

    console.log(`\nRecovered! ${txUrl(tx)}`);

    // Check final balance
    const recipientAccount = await getAccount(connection, recipientAtaAccount.address);
    console.log(`\nRecipient token balance: ${recipientAccount.amount}`);
  } else {
    console.error(`Unknown mode: ${mode}. Use "sol" or "spl".`);
    process.exit(1);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
