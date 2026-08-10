/**
 * Shared helpers for devnet portal scripts.
 *
 * Env vars:
 *   ANCHOR_WALLET  — path to operator keypair (default: ~/.config/solana/id.json)
 *   RPC_URL        — devnet RPC endpoint (default: https://api.devnet.solana.com)
 */

import { secp256k1 } from "@noble/curves/secp256k1.js";
import { Connection, Keypair, PublicKey } from "@solana/web3.js";
import { createHash } from "crypto";
import { readFileSync } from "fs";
import { resolve } from "path";

// ─── Program constants ───────────────────────────────────────────────────────

/**
 * Legacy devnet deployment. This program predates the fee-aware Relay ABI, so its
 * `bridge_relay_{sol,spl}` still take 4 args — sending the current 6-arg payload to it
 * would be silently mis-parsed, not rejected. `migrations/deploy.ts` and Anchor.toml both
 * target `declare_id!` (6cHtg7…); repoint this constant to that ID once the current binary
 * is deployed to devnet.
 */
export const DEVNET_PROGRAM_ID = new PublicKey("HuMaeg6Z81uRhYQ8ct3L3zphbKttULbyhoYGrH1AmLn8");

export const PORTAL_SEED = Buffer.from("portal");
export const PORTAL_META_SEED = Buffer.from("portal_meta");
export const CONFIG_SEED = Buffer.from("config");
export const RECOVERY_DOMAIN = Buffer.from("curvy-solana-recovery-v1");

// ─── RPC / Wallet ────────────────────────────────────────────────────────────

export function getConnection(): Connection {
  const rpcUrl = process.env.RPC_URL ?? "https://api.devnet.solana.com";
  return new Connection(rpcUrl, "confirmed");
}

export function loadKeypair(envVar = "ANCHOR_WALLET"): Keypair {
  const walletPath = process.env[envVar] ?? resolve(process.env.HOME!, ".config/solana/id.json");
  const raw = JSON.parse(readFileSync(walletPath, "utf8"));
  return Keypair.fromSecretKey(Uint8Array.from(raw));
}

// ─── Hex / bytes helpers ─────────────────────────────────────────────────────

/**
 * Convert a value to exactly 32 bytes.
 * Accepts:
 *  - bigint decimal string (e.g. Poseidon ownerHash "702705117071108...")
 *  - hex with 0x prefix ("0xabc...")
 *  - plain hex ("abc...")
 */
export function toBytes32(input: string): Uint8Array {
  let hexStr: string;
  if (input.startsWith("0x") || input.startsWith("0X")) {
    hexStr = input.slice(2);
  } else if (/^\d+$/.test(input)) {
    // Decimal bigint string — convert via BigInt
    hexStr = BigInt(input).toString(16);
  } else {
    hexStr = input;
  }
  const normalized = hexStr.padStart(64, "0").slice(-64);
  return Buffer.from(normalized, "hex");
}

export function bytesToHex(bytes: Uint8Array): string {
  return Buffer.from(bytes).toString("hex");
}

// ─── Recovery identifier ─────────────────────────────────────────────────────

export function deriveRecoveryIdentifier(secpPrivKeyHex: string): {
  recoveryIdentifier: PublicKey;
  compressedPubKey: Uint8Array;
} {
  const privKey = toBytes32(secpPrivKeyHex);
  const compressedPubKey = secp256k1.getPublicKey(privKey, true);
  const hash = createHash("sha256").update(RECOVERY_DOMAIN).update(compressedPubKey).digest();
  return {
    recoveryIdentifier: new PublicKey(hash),
    compressedPubKey,
  };
}

// ─── PDA derivation ──────────────────────────────────────────────────────────

export function deriveVaultPda(
  ownerHashBytes: Uint8Array,
  recoveryIdentifier: PublicKey,
  programId = DEVNET_PROGRAM_ID,
): [PublicKey, number] {
  return PublicKey.findProgramAddressSync([PORTAL_SEED, ownerHashBytes, recoveryIdentifier.toBuffer()], programId);
}

export function derivePortalMetaPda(
  ownerHashBytes: Uint8Array,
  recoveryIdentifier: PublicKey,
  programId = DEVNET_PROGRAM_ID,
): [PublicKey, number] {
  return PublicKey.findProgramAddressSync([PORTAL_META_SEED, ownerHashBytes, recoveryIdentifier.toBuffer()], programId);
}

export function deriveConfigPda(programId = DEVNET_PROGRAM_ID): [PublicKey, number] {
  return PublicKey.findProgramAddressSync([CONFIG_SEED], programId);
}

// ─── Recovery signature ──────────────────────────────────────────────────────

function hashv(parts: Buffer[]): Buffer {
  const h = createHash("sha256");
  for (const p of parts) h.update(p);
  return h.digest();
}

export function signSolRecovery(
  secpPrivKeyHex: string,
  programId: PublicKey,
  ownerHashBytes: Uint8Array,
  recoveryIdentifier: PublicKey,
  recipient: PublicKey,
): { signature: number[]; recoveryId: number } {
  const msgHash = hashv([
    RECOVERY_DOMAIN,
    programId.toBuffer(),
    Buffer.from(ownerHashBytes),
    recoveryIdentifier.toBuffer(),
    recipient.toBuffer(),
    Buffer.from("SOL"),
  ]);

  const privKey = toBytes32(secpPrivKeyHex);
  const sigBytes = secp256k1.sign(new Uint8Array(msgHash), privKey, {
    prehash: false,
    format: "recovered",
  });
  const recoveryId = sigBytes[0];
  const signature = Array.from(sigBytes.slice(1));
  return { signature, recoveryId };
}

export function signSplRecovery(
  secpPrivKeyHex: string,
  programId: PublicKey,
  ownerHashBytes: Uint8Array,
  recoveryIdentifier: PublicKey,
  recipient: PublicKey,
  mint: PublicKey,
): { signature: number[]; recoveryId: number } {
  const msgHash = hashv([
    RECOVERY_DOMAIN,
    programId.toBuffer(),
    Buffer.from(ownerHashBytes),
    recoveryIdentifier.toBuffer(),
    recipient.toBuffer(),
    mint.toBuffer(),
    Buffer.from("SPL"),
  ]);

  const privKey = toBytes32(secpPrivKeyHex);
  const sigBytes = secp256k1.sign(new Uint8Array(msgHash), privKey, {
    prehash: false,
    format: "recovered",
  });
  const recoveryId = sigBytes[0];
  const signature = Array.from(sigBytes.slice(1));
  return { signature, recoveryId };
}

// ─── Display helpers ─────────────────────────────────────────────────────────

export function explorerUrl(address: string): string {
  return `https://explorer.solana.com/address/${address}?cluster=devnet`;
}

export function txUrl(sig: string): string {
  return `https://explorer.solana.com/tx/${sig}?cluster=devnet`;
}

export function printPortalAddresses(
  ownerHashHex: string,
  recoveryIdentifier: PublicKey,
  vaultPda: PublicKey,
  vaultBump: number,
  metaPda: PublicKey,
  metaBump: number,
  configPda: PublicKey,
) {
  console.log("\n=== Portal Addresses (devnet) ===");
  console.log(`Program ID:           ${DEVNET_PROGRAM_ID.toBase58()}`);
  console.log(`Owner Hash:           ${ownerHashHex}`);
  console.log(`Recovery Identifier:  ${recoveryIdentifier.toBase58()}`);
  console.log(`Config PDA:           ${configPda.toBase58()}`);
  console.log(`Vault PDA:            ${vaultPda.toBase58()}  (bump: ${vaultBump})`);
  console.log(`Metadata PDA:         ${metaPda.toBase58()}  (bump: ${metaBump})`);
  console.log(`\n=== Explorer Links ===`);
  console.log(`Vault:    ${explorerUrl(vaultPda.toBase58())}`);
  console.log(`Metadata: ${explorerUrl(metaPda.toBase58())}`);
}
