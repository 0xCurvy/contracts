//@ts-nocheck
/**
 * Generate valid portal test data using curvy-wasm-core.
 *
 * Mirrors the real flow from erc3668.ts / portal.ts:
 *   1. Generate (or restore) CurvyKeyPairs via WASM core
 *   2. Call core.send(S, V) to get ephemeral keys + spendingPubKey
 *   3. Compute ownerHash = poseidon(bjjX, bjjY, sharedSecret)
 *   4. Derive Solana recovery identifier from spendingPubKey
 *   5. Derive vault + metadata PDAs
 *
 * Usage:
 *   # Generate fresh keypairs (mainnet by default):
 *   npx tsx scripts/generate-portal-data.ts
 *
 *   # Restore from existing private keys:
 *   npx tsx scripts/generate-portal-data.ts --s <spendingPrivKey> --v <viewingPrivKey>
 *
 *   # Use devnet program ID:
 *   npx tsx scripts/generate-portal-data.ts --s <s> --v <v> --cluster devnet
 *
 * Output: all data needed to run quote-bridge / execute-bridge scripts.
 */

import { Core, deriveSolanaRecoveryPubkey, poseidonHash } from "@0xcurvy/curvy-sdk";
import { secp256k1 } from "@noble/curves/secp256k1.js";
import { PublicKey } from "@solana/web3.js";
import { createHash } from "crypto";

const MAINNET_PROGRAM_ID = new PublicKey("6cHtg7sPLL9NQQuuyepnkud6PskMWV5yxvU2vXfag4qX");
const DEVNET_PROGRAM_ID = new PublicKey("HuMaeg6Z81uRhYQ8ct3L3zphbKttULbyhoYGrH1AmLn8");
const PORTAL_SEED = Buffer.from("portal");
const PORTAL_META_SEED = Buffer.from("portal_meta");
const CONFIG_SEED = Buffer.from("config");
const RECOVERY_DOMAIN = Buffer.from("curvy-solana-recovery-v1");

function parseArgs(): {
  s?: string;
  v?: string;
  cluster: "mainnet" | "devnet";
} {
  const args = process.argv.slice(2);
  const result: { s?: string; v?: string; cluster: "mainnet" | "devnet" } = {
    cluster: "mainnet",
  };
  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--s" && args[i + 1]) result.s = args[++i];
    else if (args[i] === "--v" && args[i + 1]) result.v = args[++i];
    else if (args[i] === "--cluster" && args[i + 1]) {
      const c = args[++i];
      if (c === "mainnet" || c === "devnet") result.cluster = c;
      else {
        console.error("Invalid cluster. Must be: mainnet, devnet");
        process.exit(1);
      }
    }
  }
  return result;
}

async function main() {
  const { s: existingS, v: existingV, cluster } = parseArgs();
  const programId = cluster === "mainnet" ? MAINNET_PROGRAM_ID : DEVNET_PROGRAM_ID;
  console.log(`Cluster: ${cluster}`);
  console.log(`Program: ${programId.toBase58()}`);

  // ── 1. Load WASM core and generate/restore keypairs ────────────────────
  const core = new Core();

  let keyPairs: any;
  if (existingS && existingV) {
    console.log("Restoring keypairs from provided s/v...");
    keyPairs = await core.getCurvyKeys(existingS, existingV);
  } else {
    console.log("Generating fresh keypairs...");
    keyPairs = await core.generateKeyPairs();
  }

  console.log("\n=== CurvyKeyPairs ===");
  console.log(`s (spending priv):  ${keyPairs.s}`);
  console.log(`v (viewing priv):   ${keyPairs.v}`);
  console.log(`S (spending pub):   ${keyPairs.S.slice(0, 40)}...`);
  console.log(`V (viewing pub):    ${keyPairs.V.slice(0, 40)}...`);
  console.log(`babyJubjubPubKey:   ${keyPairs.babyJubjubPublicKey.slice(0, 40)}...`);

  // ── 2. Call core.send(S, V) — ephemeral key exchange ───────────────────
  const sender = await core.send(keyPairs.S, keyPairs.V);

  console.log("\n=== Ephemeral Data (from core.send) ===");
  console.log(`R (ephemeral pub):  ${sender.R.slice(0, 40)}...`);
  console.log(`viewTag:            ${sender.viewTag}`);
  console.log(`spendingPubKey:     ${sender.spendingPubKey.slice(0, 40)}...`);

  // ── 3. Compute ownerHash = poseidon(bjjX, bjjY, sharedSecret) ──────────
  const [bjjX, bjjY] = keyPairs.babyJubjubPublicKey.split(".");
  const sharedSecret = sender.spendingPubKey.split(".")[0];

  const ownerHash = poseidonHash([BigInt(bjjX!), BigInt(bjjY!), BigInt(sharedSecret!)]).toString();

  // Convert to 32-byte hex for Solana seeds
  const ownerHashHex = `0x${BigInt(ownerHash).toString(16).padStart(64, "0")}`;

  console.log("\n=== Owner Hash ===");
  console.log(`ownerHash (bigint): ${ownerHash}`);
  console.log(`ownerHash (hex):    ${ownerHashHex}`);

  // ── 4. Derive secp256k1 stealth private key for recovery ───────────────
  //
  // The spendingPubKey from core.send() is a SECP256k1 point.
  // The corresponding private key is derived by the recipient via core.scan().
  // For testing, we derive the stealth private key using the same WASM:
  //   scan(s, v, [R], [viewTag]) → spendingPrivKeys[0]
  //
  const scanResult = await core.scan(keyPairs.s, keyPairs.v, [
    { ephemeralPublicKey: sender.R, viewTag: sender.viewTag },
  ]);

  // The scan returns the stealth spending private key (hex string)
  const stealthPrivKey = scanResult.spendingPrivKeys[0];
  if (!stealthPrivKey) {
    throw new Error("scan() did not return a stealth private key — viewTag mismatch?");
  }

  console.log("\n=== Stealth / Recovery Key ===");
  console.log(`stealthPrivKey:     ${stealthPrivKey}`);

  // ── 5. Derive Solana recovery identifier ───────────────────────────────
  //
  // Same as deriveSolanaRecoveryPubkey() in SDK but we also need the
  // raw compressed pubkey bytes for the devnet scripts.
  //
  const stealthPrivKeyHex = stealthPrivKey.replace(/^0x/i, "").padStart(64, "0");
  const stealthPrivKeyBytes = Buffer.from(stealthPrivKeyHex, "hex");
  const compressedPubKey = secp256k1.getPublicKey(stealthPrivKeyBytes, true);

  const recoveryIdentifierHash = createHash("sha256").update(RECOVERY_DOMAIN).update(compressedPubKey).digest();
  const recoveryIdentifier = new PublicKey(recoveryIdentifierHash);

  // Cross-check with SDK's deriveSolanaRecoveryPubkey
  const sdkRecovery = deriveSolanaRecoveryPubkey(sender.spendingPubKey);
  if (sdkRecovery !== recoveryIdentifier.toBase58()) {
    console.warn("\nWARNING: SDK deriveSolanaRecoveryPubkey mismatch!");
    console.warn(`  SDK:     ${sdkRecovery}`);
    console.warn(`  Script:  ${recoveryIdentifier.toBase58()}`);
  }

  console.log(`recoveryIdentifier: ${recoveryIdentifier.toBase58()}`);

  // ── 6. Derive PDAs ─────────────────────────────────────────────────────
  const ownerHashBytes = Buffer.from(BigInt(ownerHash).toString(16).padStart(64, "0"), "hex");

  const [vaultPda, vaultBump] = PublicKey.findProgramAddressSync(
    [PORTAL_SEED, ownerHashBytes, recoveryIdentifier.toBuffer()],
    programId,
  );

  const [metaPda, metaBump] = PublicKey.findProgramAddressSync(
    [PORTAL_META_SEED, ownerHashBytes, recoveryIdentifier.toBuffer()],
    programId,
  );

  const [configPda] = PublicKey.findProgramAddressSync([CONFIG_SEED], programId);

  console.log(`\n=== Solana Portal PDAs (${cluster}) ===`);
  console.log(`Program ID:         ${programId.toBase58()}`);
  console.log(`Config PDA:         ${configPda.toBase58()}`);
  console.log(`Vault PDA:          ${vaultPda.toBase58()}  (bump: ${vaultBump})`);
  console.log(`Metadata PDA:       ${metaPda.toBase58()}  (bump: ${metaBump})`);

  // ── 7. Print ready-to-use commands ─────────────────────────────────────
  console.log("\n=== Ready-to-use Commands ===\n");

  const clusterFlag = `--cluster ${cluster}`;
  const deriveCmd = cluster === "mainnet" ? "mainnet:derive" : "devnet:derive";

  console.log("# Derive & inspect on-chain state:");
  console.log(`yarn ${deriveCmd} ${ownerHash} ${stealthPrivKey}\n`);

  console.log("# Fund vault with SOL (send directly to vault PDA):");
  console.log(
    `solana transfer ${vaultPda.toBase58()} 0.1 --url ${cluster === "mainnet" ? "mainnet-beta" : "devnet"}\n`,
  );

  console.log("# Get bridge quote:");
  console.log(`yarn quote-bridge --ownerHash ${ownerHash} --recoveryKey ${stealthPrivKey} ${clusterFlag}\n`);

  console.log("# Execute bridge:");
  console.log(
    `yarn execute-bridge --ownerHash ${ownerHash} --recoveryKey ${stealthPrivKey} ${clusterFlag} --dry-run\n`,
  );

  // ── 8. JSON export for programmatic use ────────────────────────────────
  const output = {
    curvyKeyPairs: {
      s: keyPairs.s,
      v: keyPairs.v,
      S: keyPairs.S,
      V: keyPairs.V,
      babyJubjubPublicKey: keyPairs.babyJubjubPublicKey,
    },
    ephemeral: {
      R: sender.R,
      viewTag: sender.viewTag,
      spendingPubKey: sender.spendingPubKey,
    },
    ownerHash,
    ownerHashHex,
    stealthPrivKey,
    recoveryIdentifier: recoveryIdentifier.toBase58(),
    vaultPda: vaultPda.toBase58(),
    metaPda: metaPda.toBase58(),
    configPda: configPda.toBase58(),
  };

  console.log("\n=== JSON (for programmatic use) ===");
  console.log(JSON.stringify(output, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
