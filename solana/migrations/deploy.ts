//@ts-nocheck

import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { PublicKey } from "@solana/web3.js";
import { createRequire } from "module";
import type { CurvyPortal } from "../target/types/curvy_portal.js";

const require = createRequire(import.meta.url);
const idl = require("../target/idl/curvy_portal.json");

const CONFIG_SEED = Buffer.from("config");

async function main() {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const programId = new PublicKey(idl.address);
  const program = new Program<CurvyPortal>(idl, provider);

  console.log("Program ID:", programId.toBase58());
  console.log("Authority:", provider.wallet.publicKey.toBase58());

  // Derive config PDA
  const [configPda] = PublicKey.findProgramAddressSync([CONFIG_SEED], programId);

  console.log("Config PDA:", configPda.toBase58());

  // Operator wallet — set this to the backend operator's pubkey
  const operatorWallet = getOperatorPubkey(provider);

  console.log("Operator:", operatorWallet.toBase58());

  // Check if config already exists
  try {
    const existingConfig = await program.account.portalConfig.fetch(configPda);
    console.log("Config already initialized:");
    console.log("  Authority:", existingConfig.authority.toBase58());
    console.log("  Operator:", existingConfig.operator.toBase58());
    console.log("  Destination Chain ID:", existingConfig.destinationChainId.toString());
    return;
  } catch {
    // Config doesn't exist yet — proceed with initialization
  }

  // Initialize config
  const tx = await program.methods
    .initialize(operatorWallet)
    .accounts({
      authority: provider.wallet.publicKey,
    })
    .rpc();

  console.log("Config initialized. Transaction:", tx);

  // Verify
  const config = await program.account.portalConfig.fetch(configPda);
  console.log("Verified config:");
  console.log("  Authority:", config.authority.toBase58());
  console.log("  Operator:", config.operator.toBase58());
  console.log("  Destination Chain ID:", config.destinationChainId.toString());
}

function getOperatorPubkey(provider: anchor.AnchorProvider): PublicKey {
  const operatorEnv = process.env.PORTAL_OPERATOR_PUBKEY;
  if (operatorEnv) {
    return new PublicKey(operatorEnv);
  }
  console.warn("WARNING: No PORTAL_OPERATOR_PUBKEY set — using deployer wallet as operator");
  return provider.wallet.publicKey;
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
