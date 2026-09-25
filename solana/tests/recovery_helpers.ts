import { secp256k1 } from "@noble/curves/secp256k1.js";
import { PublicKey } from "@solana/web3.js";
import { createHash } from "crypto";

export const SOLANA_RECOVERY_DOMAIN = Buffer.from("curvy-solana-recovery-v1");

export function hashv(parts: Buffer[]): Buffer {
  const h = createHash("sha256");
  for (const p of parts) h.update(p);
  return h.digest();
}

export function secpPrivFromSeed(seed: string): Uint8Array {
  return new Uint8Array(createHash("sha256").update(seed, "utf8").digest());
}

export function randomSecpPriv(): Uint8Array {
  return secp256k1.utils.randomSecretKey();
}

export function recoveryIdentifierFromSecpPriv(priv: Uint8Array): PublicKey {
  const compressed = secp256k1.getPublicKey(priv, true);
  const digest = hashv([SOLANA_RECOVERY_DOMAIN, Buffer.from(compressed)]);
  return new PublicKey(digest);
}

export function pubkeyToArray32(pk: PublicKey): number[] {
  return Array.from(pk.toBytes());
}

export function solRecoveryMessageHash(
  programId: PublicKey,
  ownerHash: number[],
  recoveryIdPk: PublicKey,
  recipient: PublicKey,
): Uint8Array {
  const digest = hashv([
    SOLANA_RECOVERY_DOMAIN,
    programId.toBuffer(),
    Buffer.from(ownerHash),
    recoveryIdPk.toBuffer(),
    recipient.toBuffer(),
    Buffer.from("SOL"),
  ]);
  return new Uint8Array(digest);
}

export function splRecoveryMessageHash(
  programId: PublicKey,
  ownerHash: number[],
  recoveryIdPk: PublicKey,
  recipient: PublicKey,
  mint: PublicKey,
): Uint8Array {
  const digest = hashv([
    SOLANA_RECOVERY_DOMAIN,
    programId.toBuffer(),
    Buffer.from(ownerHash),
    recoveryIdPk.toBuffer(),
    recipient.toBuffer(),
    mint.toBuffer(),
    Buffer.from("SPL"),
  ]);
  return new Uint8Array(digest);
}

export function signSolRecovery(
  priv: Uint8Array,
  programId: PublicKey,
  ownerHash: number[],
  recoveryIdPk: PublicKey,
  recipient: PublicKey,
): { signature: number[]; recoveryId: number } {
  const msgHash = solRecoveryMessageHash(programId, ownerHash, recoveryIdPk, recipient);
  const sigBytes = secp256k1.sign(msgHash, priv, {
    prehash: false,
    format: "recovered",
  });
  const recoveryId = sigBytes[0];
  const signature = Array.from(sigBytes.slice(1));
  return { signature, recoveryId };
}

export function signSplRecovery(
  priv: Uint8Array,
  programId: PublicKey,
  ownerHash: number[],
  recoveryIdPk: PublicKey,
  recipient: PublicKey,
  mint: PublicKey,
): { signature: number[]; recoveryId: number } {
  const msgHash = splRecoveryMessageHash(programId, ownerHash, recoveryIdPk, recipient, mint);
  const sigBytes = secp256k1.sign(msgHash, priv, {
    prehash: false,
    format: "recovered",
  });
  const recoveryId = sigBytes[0];
  const signature = Array.from(sigBytes.slice(1));
  return { signature, recoveryId };
}
