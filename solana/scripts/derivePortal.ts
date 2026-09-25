/**
 * Derive portal PDA addresses for a given ownerHash + recovery identifier.
 *
 * Usage:
 *   npx tsx scripts/derive-portal.ts <ownerHash (hex)> <secp256k1PrivKey (hex)>
 *
 * Example:
 *   npx tsx scripts/derive-portal.ts \
 *     0xabc123...  \
 *     0xdeadbeef...
 */

import { secp256k1 } from "@noble/curves/secp256k1.js";
import { PublicKey } from "@solana/web3.js";
import { createHash } from "crypto";

const PROGRAM_ID = new PublicKey("6cHtg7sPLL9NQQuuyepnkud6PskMWV5yxvU2vXfag4qX");
const PORTAL_SEED = Buffer.from("portal");
const PORTAL_META_SEED = Buffer.from("portal_meta");
const CONFIG_SEED = Buffer.from("config");
const RECOVERY_DOMAIN = Buffer.from("curvy-solana-recovery-v1");

function deriveRecoveryIdentifier(privKeyHex: string): PublicKey {
  const privKey = hexToBytes(privKeyHex);
  const compressedPubKey = secp256k1.getPublicKey(privKey, true);
  const hash = createHash("sha256").update(RECOVERY_DOMAIN).update(compressedPubKey).digest();
  return new PublicKey(hash);
}

function hexToBytes(input: string): Uint8Array {
  let hexStr: string;

  if (input.startsWith("0x") || input.startsWith("0X")) {
    // Hex string with 0x prefix
    hexStr = input.slice(2);
  } else if (/^\d+$/.test(input)) {
    // Decimal number — convert via BigInt
    hexStr = BigInt(input).toString(16);
  } else {
    // Plain hex string without prefix
    hexStr = input;
  }

  // Always produce exactly 32 bytes (64 hex chars) — Solana seed limit
  const normalized = hexStr.padStart(64, "0").slice(-64);
  return Buffer.from(normalized, "hex");
}

function deriveAddresses(ownerHashHex: string, recoveryIdentifier: PublicKey) {
  const ownerHashBytes = hexToBytes(ownerHashHex);

  const [vaultPda, vaultBump] = PublicKey.findProgramAddressSync(
    [PORTAL_SEED, ownerHashBytes, recoveryIdentifier.toBuffer()],
    PROGRAM_ID,
  );

  const [metaPda, metaBump] = PublicKey.findProgramAddressSync(
    [PORTAL_META_SEED, ownerHashBytes, recoveryIdentifier.toBuffer()],
    PROGRAM_ID,
  );

  const [configPda] = PublicKey.findProgramAddressSync([CONFIG_SEED], PROGRAM_ID);

  return { vaultPda, vaultBump, metaPda, metaBump, configPda };
}

const [ownerHashArg, privKeyArg] = process.argv.slice(2);

if (!ownerHashArg || !privKeyArg) {
  console.error("Usage: npx tsx scripts/derive-portal.ts <ownerHash hex> <secp256k1PrivKey hex>");
  process.exit(1);
}

const recoveryIdentifier = deriveRecoveryIdentifier(privKeyArg);
const { vaultPda, vaultBump, metaPda, metaBump, configPda } = deriveAddresses(ownerHashArg, recoveryIdentifier);

console.log("\n=== Portal Addresses ===");
console.log(`Program ID:           ${PROGRAM_ID.toBase58()}`);
console.log(`Config PDA:           ${configPda.toBase58()}`);
console.log(`Recovery Identifier:  ${recoveryIdentifier.toBase58()}`);
console.log(`Vault PDA:            ${vaultPda.toBase58()}  (bump: ${vaultBump})`);
console.log(`Metadata PDA:         ${metaPda.toBase58()}  (bump: ${metaBump})`);
console.log("\n=== Solana Explorer (devnet) ===");
console.log(`Vault:    https://explorer.solana.com/address/${vaultPda.toBase58()}?cluster=devnet`);
console.log(`Metadata: https://explorer.solana.com/address/${metaPda.toBase58()}?cluster=devnet`);
console.log(`Program:  https://explorer.solana.com/address/${PROGRAM_ID.toBase58()}?cluster=devnet`);
