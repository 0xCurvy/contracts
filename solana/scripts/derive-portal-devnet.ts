/**
 * Derive portal addresses on devnet and check on-chain state.
 *
 * Usage:
 *   npx tsx scripts/derive-portal-devnet.ts <ownerHash> <secp256k1PrivKey (hex)>
 *
 * ownerHash accepts: decimal bigint string (Poseidon output), 0x-hex, or plain hex.
 *
 * Example:
 *   npx tsx scripts/derive-portal-devnet.ts \
 *     702705117071108858750548073842146797693190729490869702449519502701872077655 \
 *     0xdeadbeef...1234
 */

import {
  deriveConfigPda,
  derivePortalMetaPda,
  deriveRecoveryIdentifier,
  deriveVaultPda,
  getConnection,
  printPortalAddresses,
  toBytes32,
} from "./devnet-helpers.js";

async function main() {
  const [ownerHashArg, privKeyArg] = process.argv.slice(2);

  if (!ownerHashArg || !privKeyArg) {
    console.error("Usage: npx tsx scripts/derive-portal-devnet.ts <ownerHash (bigint|hex)> <secp256k1PrivKey hex>");
    process.exit(1);
  }

  const connection = getConnection();
  const ownerHashBytes = toBytes32(ownerHashArg);
  const { recoveryIdentifier, compressedPubKey } = deriveRecoveryIdentifier(privKeyArg);

  const [vaultPda, vaultBump] = deriveVaultPda(ownerHashBytes, recoveryIdentifier);
  const [metaPda, metaBump] = derivePortalMetaPda(ownerHashBytes, recoveryIdentifier);
  const [configPda] = deriveConfigPda();

  printPortalAddresses(ownerHashArg, recoveryIdentifier, vaultPda, vaultBump, metaPda, metaBump, configPda);

  // Check on-chain state
  console.log("\n=== On-chain State ===");

  const configInfo = await connection.getAccountInfo(configPda);
  if (configInfo) {
    console.log(`Config:    EXISTS (${configInfo.data.length} bytes, owner: ${configInfo.owner.toBase58()})`);
  } else {
    console.log("Config:    NOT INITIALIZED — run init:devnet first");
  }

  const vaultInfo = await connection.getAccountInfo(vaultPda);
  if (vaultInfo) {
    const solBalance = vaultInfo.lamports / 1e9;
    console.log(`Vault:     EXISTS (${solBalance} SOL, owner: ${vaultInfo.owner.toBase58()})`);
  } else {
    console.log("Vault:     NOT CREATED — use fund-portal-devnet to create");
  }

  const metaInfo = await connection.getAccountInfo(metaPda);
  if (metaInfo) {
    console.log(`Metadata:  EXISTS (${metaInfo.data.length} bytes, owner: ${metaInfo.owner.toBase58()})`);
  } else {
    console.log("Metadata:  NOT CREATED (created during bridge)");
  }

  // Check SPL ATAs if vault exists
  if (vaultInfo) {
    const { TOKEN_PROGRAM_ID } = await import("@solana/spl-token");
    const tokenAccounts = await connection.getTokenAccountsByOwner(vaultPda, {
      programId: TOKEN_PROGRAM_ID,
    });

    if (tokenAccounts.value.length > 0) {
      console.log(`\n=== Vault SPL Token Accounts ===`);
      for (const { pubkey, account } of tokenAccounts.value) {
        const amount = account.data.readBigUInt64LE(64);
        const mintBytes = account.data.subarray(0, 32);
        const { PublicKey } = await import("@solana/web3.js");
        const mint = new PublicKey(mintBytes);
        console.log(`  ATA: ${pubkey.toBase58()}`);
        console.log(`    Mint:   ${mint.toBase58()}`);
        console.log(`    Amount: ${amount.toString()}`);
      }
    } else {
      console.log("\nNo SPL token accounts found for vault.");
    }
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
