/**
 * Derive portal addresses on mainnet and check on-chain state.
 *
 * Usage:
 *   npx tsx scripts/derive-portal-mainnet.ts <ownerHash> <secp256k1PrivKey (hex)>
 *
 * ownerHash accepts: decimal bigint string (Poseidon output), 0x-hex, or plain hex.
 *
 * Env:
 *   RPC_URL — mainnet RPC (default: https://api.mainnet-beta.solana.com)
 */

import { TOKEN_PROGRAM_ID } from "@solana/spl-token";
import { Connection, PublicKey } from "@solana/web3.js";
import { CONFIG_SEED, deriveRecoveryIdentifier, PORTAL_META_SEED, PORTAL_SEED, toBytes32 } from "./devnet-helpers.js";

const MAINNET_PROGRAM_ID = new PublicKey("6cHtg7sPLL9NQQuuyepnkud6PskMWV5yxvU2vXfag4qX");

function getMainnetConnection(): Connection {
  const rpcUrl = process.env.RPC_URL ?? "https://api.mainnet-beta.solana.com";
  return new Connection(rpcUrl, "confirmed");
}

function explorerUrl(address: string): string {
  return `https://explorer.solana.com/address/${address}`;
}

async function main() {
  const [ownerHashArg, privKeyArg] = process.argv.slice(2);

  if (!ownerHashArg || !privKeyArg) {
    console.error("Usage: npx tsx scripts/derive-portal-mainnet.ts <ownerHash (bigint|hex)> <secp256k1PrivKey hex>");
    process.exit(1);
  }

  const connection = getMainnetConnection();
  const ownerHashBytes = toBytes32(ownerHashArg);
  const { recoveryIdentifier } = deriveRecoveryIdentifier(privKeyArg);

  const [vaultPda, vaultBump] = PublicKey.findProgramAddressSync(
    [PORTAL_SEED, ownerHashBytes, recoveryIdentifier.toBuffer()],
    MAINNET_PROGRAM_ID,
  );
  const [metaPda, metaBump] = PublicKey.findProgramAddressSync(
    [PORTAL_META_SEED, ownerHashBytes, recoveryIdentifier.toBuffer()],
    MAINNET_PROGRAM_ID,
  );
  const [configPda] = PublicKey.findProgramAddressSync([CONFIG_SEED], MAINNET_PROGRAM_ID);

  console.log("\n=== Portal Addresses (mainnet) ===");
  console.log(`Program ID:           ${MAINNET_PROGRAM_ID.toBase58()}`);
  console.log(`Owner Hash:           ${ownerHashArg}`);
  console.log(`Recovery Identifier:  ${recoveryIdentifier.toBase58()}`);
  console.log(`Config PDA:           ${configPda.toBase58()}`);
  console.log(`Vault PDA:            ${vaultPda.toBase58()}  (bump: ${vaultBump})`);
  console.log(`Metadata PDA:         ${metaPda.toBase58()}  (bump: ${metaBump})`);
  console.log(`\n=== Explorer Links ===`);
  console.log(`Vault:    ${explorerUrl(vaultPda.toBase58())}`);
  console.log(`Metadata: ${explorerUrl(metaPda.toBase58())}`);

  // Check on-chain state
  console.log("\n=== On-chain State ===");

  const configInfo = await connection.getAccountInfo(configPda);
  if (configInfo) {
    console.log(`Config:    EXISTS (${configInfo.data.length} bytes, owner: ${configInfo.owner.toBase58()})`);
  } else {
    console.log("Config:    NOT INITIALIZED — run init:mainnet first");
  }

  const vaultInfo = await connection.getAccountInfo(vaultPda);
  if (vaultInfo) {
    const solBalance = vaultInfo.lamports / 1e9;
    console.log(`Vault:     EXISTS (${solBalance} SOL, owner: ${vaultInfo.owner.toBase58()})`);
  } else {
    console.log("Vault:     NOT CREATED");
  }

  const metaInfo = await connection.getAccountInfo(metaPda);
  if (metaInfo) {
    console.log(`Metadata:  EXISTS (${metaInfo.data.length} bytes, owner: ${metaInfo.owner.toBase58()})`);
  } else {
    console.log("Metadata:  NOT CREATED");
  }

  // Check SPL ATAs if vault exists
  if (vaultInfo) {
    const tokenAccounts = await connection.getTokenAccountsByOwner(vaultPda, {
      programId: TOKEN_PROGRAM_ID,
    });

    if (tokenAccounts.value.length > 0) {
      console.log(`\n=== Vault SPL Token Accounts ===`);
      for (const { pubkey, account } of tokenAccounts.value) {
        const amount = account.data.readBigUInt64LE(64);
        const mintBytes = account.data.subarray(0, 32);
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
