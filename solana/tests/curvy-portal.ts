import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import {
  Keypair,
  LAMPORTS_PER_SOL,
  PublicKey,
  SystemProgram,
} from "@solana/web3.js";
import {
  createMint,
  getOrCreateAssociatedTokenAccount,
  mintTo,
  TOKEN_PROGRAM_ID,
  ASSOCIATED_TOKEN_PROGRAM_ID,
  getAccount,
} from "@solana/spl-token";
import { expect } from "chai";
import type { CurvyPortal } from "../target/types/curvy_portal";

const CONFIG_SEED = Buffer.from("config");
const PORTAL_SEED = Buffer.from("portal");
const PORTAL_META_SEED = Buffer.from("portal_meta");

describe("curvy-portal", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.CurvyPortal as Program<CurvyPortal>;
  const authority = provider.wallet as anchor.Wallet;
  const operator = Keypair.generate();
  const recovery = Keypair.generate();

  // A sample owner hash (32 bytes, non-zero)
  const ownerHash = Buffer.alloc(32);
  ownerHash.writeUInt32BE(12345, 28);

  let configPda: PublicKey;
  let vaultPda: PublicKey;
  let vaultBump: number;
  let portalMetaPda: PublicKey;

  before(async () => {
    // Derive PDAs
    [configPda] = PublicKey.findProgramAddressSync(
      [CONFIG_SEED],
      program.programId,
    );

    [vaultPda, vaultBump] = PublicKey.findProgramAddressSync(
      [PORTAL_SEED, ownerHash, recovery.publicKey.toBuffer()],
      program.programId,
    );

    [portalMetaPda] = PublicKey.findProgramAddressSync(
      [PORTAL_META_SEED, ownerHash, recovery.publicKey.toBuffer()],
      program.programId,
    );

    // Fund operator
    const sig = await provider.connection.requestAirdrop(
      operator.publicKey,
      10 * LAMPORTS_PER_SOL,
    );
    await provider.connection.confirmTransaction(sig);
  });

  describe("initialize", () => {
    it("initializes config", async () => {
      await program.methods
        .initialize(operator.publicKey)
        .accounts({
          authority: authority.publicKey,
          config: configPda,
          systemProgram: SystemProgram.programId,
        })
        .rpc();

      const config = await program.account.portalConfig.fetch(configPda);
      expect(config.authority.toBase58()).to.equal(
        authority.publicKey.toBase58(),
      );
      expect(config.operator.toBase58()).to.equal(
        operator.publicKey.toBase58(),
      );
      expect(config.destinationChainId.toNumber()).to.equal(42161);
    });

    it("fails to initialize twice", async () => {
      try {
        await program.methods
          .initialize(operator.publicKey)
          .accounts({
            authority: authority.publicKey,
            config: configPda,
            systemProgram: SystemProgram.programId,
          })
          .rpc();
        expect.fail("Should have thrown");
      } catch (err: any) {
        // Account already exists
        expect(err).to.exist;
      }
    });
  });

  describe("update_config", () => {
    it("updates operator", async () => {
      const newOperator = Keypair.generate();

      await program.methods
        .updateConfig(newOperator.publicKey, null)
        .accounts({
          authority: authority.publicKey,
          config: configPda,
        })
        .rpc();

      let config = await program.account.portalConfig.fetch(configPda);
      expect(config.operator.toBase58()).to.equal(
        newOperator.publicKey.toBase58(),
      );

      // Restore original operator
      await program.methods
        .updateConfig(operator.publicKey, null)
        .accounts({
          authority: authority.publicKey,
          config: configPda,
        })
        .rpc();

      config = await program.account.portalConfig.fetch(configPda);
      expect(config.operator.toBase58()).to.equal(
        operator.publicKey.toBase58(),
      );
    });

    it("rejects non-authority", async () => {
      const impostor = Keypair.generate();
      const sig = await provider.connection.requestAirdrop(
        impostor.publicKey,
        LAMPORTS_PER_SOL,
      );
      await provider.connection.confirmTransaction(sig);

      try {
        await program.methods
          .updateConfig(impostor.publicKey, null)
          .accounts({
            authority: impostor.publicKey,
            config: configPda,
          })
          .signers([impostor])
          .rpc();
        expect.fail("Should have thrown");
      } catch (err: any) {
        expect(err.error?.errorCode?.code || err.message).to.include(
          "UnauthorizedAuthority",
        );
      }
    });
  });

  describe("create_and_bridge_sol", () => {
    const depositAmount = 2 * LAMPORTS_PER_SOL;

    before(async () => {
      // Send SOL to the vault PDA (simulating a user deposit)
      const tx = new anchor.web3.Transaction().add(
        SystemProgram.transfer({
          fromPubkey: authority.publicKey,
          toPubkey: vaultPda,
          lamports: depositAmount,
        }),
      );
      await provider.sendAndConfirm(tx);

      const balance = await provider.connection.getBalance(vaultPda);
      expect(balance).to.equal(depositAmount);
    });

    it("withdraws SOL from vault to operator", async () => {
      const operatorBalanceBefore = await provider.connection.getBalance(
        operator.publicKey,
      );

      await program.methods
        .createAndBridgeSol(Array.from(ownerHash) as any)
        .accounts({
          operator: operator.publicKey,
          config: configPda,
          portal: portalMetaPda,
          vault: vaultPda,
          recovery: recovery.publicKey,
          destination: operator.publicKey,
          systemProgram: SystemProgram.programId,
        })
        .signers([operator])
        .rpc();

      // Verify vault is empty
      const vaultBalance = await provider.connection.getBalance(vaultPda);
      expect(vaultBalance).to.equal(0);

      // Verify operator received the SOL
      const operatorBalanceAfter = await provider.connection.getBalance(
        operator.publicKey,
      );
      // Account for the rent paid for portal_meta account
      expect(operatorBalanceAfter).to.be.greaterThan(operatorBalanceBefore);

      // Verify portal metadata
      const portal = await program.account.portalAccount.fetch(portalMetaPda);
      expect(portal.isUsed).to.be.true;
      expect(Buffer.from(portal.ownerHash)).to.deep.equal(ownerHash);
      expect(portal.recovery.toBase58()).to.equal(
        recovery.publicKey.toBase58(),
      );
      expect(portal.amountWithdrawn.toNumber()).to.equal(depositAmount);
      expect(portal.currencyMint.toBase58()).to.equal(
        PublicKey.default.toBase58(),
      );
    });

    it("fails on second bridge attempt (single-use)", async () => {
      try {
        await program.methods
          .createAndBridgeSol(Array.from(ownerHash) as any)
          .accounts({
            operator: operator.publicKey,
            config: configPda,
            portal: portalMetaPda,
            vault: vaultPda,
            recovery: recovery.publicKey,
            destination: operator.publicKey,
            systemProgram: SystemProgram.programId,
          })
          .signers([operator])
          .rpc();
        expect.fail("Should have thrown");
      } catch (err: any) {
        // init constraint fails — account already exists
        expect(err).to.exist;
      }
    });

    it("rejects non-operator", async () => {
      const impostor = Keypair.generate();
      const sig = await provider.connection.requestAirdrop(
        impostor.publicKey,
        LAMPORTS_PER_SOL,
      );
      await provider.connection.confirmTransaction(sig);

      const otherOwnerHash = Buffer.alloc(32);
      otherOwnerHash.writeUInt32BE(99999, 28);

      const [otherVault] = PublicKey.findProgramAddressSync(
        [PORTAL_SEED, otherOwnerHash, recovery.publicKey.toBuffer()],
        program.programId,
      );
      const [otherMeta] = PublicKey.findProgramAddressSync(
        [PORTAL_META_SEED, otherOwnerHash, recovery.publicKey.toBuffer()],
        program.programId,
      );

      try {
        await program.methods
          .createAndBridgeSol(Array.from(otherOwnerHash) as any)
          .accounts({
            operator: impostor.publicKey,
            config: configPda,
            portal: otherMeta,
            vault: otherVault,
            recovery: recovery.publicKey,
            destination: impostor.publicKey,
            systemProgram: SystemProgram.programId,
          })
          .signers([impostor])
          .rpc();
        expect.fail("Should have thrown");
      } catch (err: any) {
        expect(err.error?.errorCode?.code || err.message).to.include(
          "UnauthorizedOperator",
        );
      }
    });
  });

  describe("create_and_bridge_spl", () => {
    const splOwnerHash = Buffer.alloc(32);
    splOwnerHash.writeUInt32BE(67890, 28);

    let mint: PublicKey;
    let splVaultPda: PublicKey;
    let splPortalMetaPda: PublicKey;
    let vaultAta: PublicKey;
    let operatorAta: PublicKey;
    const depositAmount = 1_000_000_000; // 1 token with 9 decimals

    before(async () => {
      [splVaultPda] = PublicKey.findProgramAddressSync(
        [PORTAL_SEED, splOwnerHash, recovery.publicKey.toBuffer()],
        program.programId,
      );
      [splPortalMetaPda] = PublicKey.findProgramAddressSync(
        [PORTAL_META_SEED, splOwnerHash, recovery.publicKey.toBuffer()],
        program.programId,
      );

      // Create a mint
      mint = await createMint(
        provider.connection,
        authority.payer,
        authority.publicKey,
        null,
        9,
      );

      // Create vault ATA and mint tokens to it (simulating user deposit)
      const vaultAtaAccount = await getOrCreateAssociatedTokenAccount(
        provider.connection,
        authority.payer,
        mint,
        splVaultPda,
        true, // allowOwnerOffCurve for PDA
      );
      vaultAta = vaultAtaAccount.address;

      await mintTo(
        provider.connection,
        authority.payer,
        mint,
        vaultAta,
        authority.publicKey,
        depositAmount,
      );

      // Create operator ATA
      const operatorAtaAccount = await getOrCreateAssociatedTokenAccount(
        provider.connection,
        authority.payer,
        mint,
        operator.publicKey,
      );
      operatorAta = operatorAtaAccount.address;
    });

    it("withdraws SPL tokens from vault to operator", async () => {
      await program.methods
        .createAndBridgeSpl(Array.from(splOwnerHash) as any)
        .accounts({
          operator: operator.publicKey,
          config: configPda,
          portal: splPortalMetaPda,
          vault: splVaultPda,
          vaultTokenAccount: vaultAta,
          destinationTokenAccount: operatorAta,
          mint: mint,
          recovery: recovery.publicKey,
          tokenProgram: TOKEN_PROGRAM_ID,
          associatedTokenProgram: ASSOCIATED_TOKEN_PROGRAM_ID,
          systemProgram: SystemProgram.programId,
        })
        .signers([operator])
        .rpc();

      // Verify operator received tokens
      const operatorTokenAccount = await getAccount(
        provider.connection,
        operatorAta,
      );
      expect(Number(operatorTokenAccount.amount)).to.equal(depositAmount);

      // Verify vault ATA is empty
      const vaultTokenAccount = await getAccount(
        provider.connection,
        vaultAta,
      );
      expect(Number(vaultTokenAccount.amount)).to.equal(0);

      // Verify portal metadata
      const portal = await program.account.portalAccount.fetch(
        splPortalMetaPda,
      );
      expect(portal.isUsed).to.be.true;
      expect(portal.amountWithdrawn.toNumber()).to.equal(depositAmount);
      expect(portal.currencyMint.toBase58()).to.equal(mint.toBase58());
    });
  });

  describe("recover_sol", () => {
    const recoverOwnerHash = Buffer.alloc(32);
    recoverOwnerHash.writeUInt32BE(11111, 28);

    let recoverVaultPda: PublicKey;
    let recoverMetaPda: PublicKey;
    const depositAmount = LAMPORTS_PER_SOL;

    before(async () => {
      [recoverVaultPda] = PublicKey.findProgramAddressSync(
        [PORTAL_SEED, recoverOwnerHash, recovery.publicKey.toBuffer()],
        program.programId,
      );
      [recoverMetaPda] = PublicKey.findProgramAddressSync(
        [PORTAL_META_SEED, recoverOwnerHash, recovery.publicKey.toBuffer()],
        program.programId,
      );

      // Fund the vault PDA
      const tx = new anchor.web3.Transaction().add(
        SystemProgram.transfer({
          fromPubkey: authority.publicKey,
          toPubkey: recoverVaultPda,
          lamports: depositAmount,
        }),
      );
      await provider.sendAndConfirm(tx);
    });

    it("recovers SOL from uninitialized portal", async () => {
      const recipient = Keypair.generate();

      // Fund recovery signer for tx fees
      const sig = await provider.connection.requestAirdrop(
        recovery.publicKey,
        LAMPORTS_PER_SOL,
      );
      await provider.connection.confirmTransaction(sig);

      await program.methods
        .recoverSol(Array.from(recoverOwnerHash) as any)
        .accounts({
          recoverySigner: recovery.publicKey,
          vault: recoverVaultPda,
          recipient: recipient.publicKey,
          portalMeta: recoverMetaPda,
          systemProgram: SystemProgram.programId,
        })
        .signers([recovery])
        .rpc();

      const recipientBalance = await provider.connection.getBalance(
        recipient.publicKey,
      );
      expect(recipientBalance).to.equal(depositAmount);

      const vaultBalance = await provider.connection.getBalance(
        recoverVaultPda,
      );
      expect(vaultBalance).to.equal(0);
    });

    it("rejects wrong recovery signer", async () => {
      const wrongSigner = Keypair.generate();
      const sig = await provider.connection.requestAirdrop(
        wrongSigner.publicKey,
        LAMPORTS_PER_SOL,
      );
      await provider.connection.confirmTransaction(sig);

      // Wrong recovery signer will derive a different PDA — seeds won't match
      const [wrongVault] = PublicKey.findProgramAddressSync(
        [PORTAL_SEED, recoverOwnerHash, wrongSigner.publicKey.toBuffer()],
        program.programId,
      );

      // Fund the wrong vault so it has something
      const fundTx = new anchor.web3.Transaction().add(
        SystemProgram.transfer({
          fromPubkey: authority.publicKey,
          toPubkey: wrongVault,
          lamports: LAMPORTS_PER_SOL / 10,
        }),
      );
      await provider.sendAndConfirm(fundTx);

      // Trying to recover from the ORIGINAL vault with wrong signer will fail
      // because the PDA seeds won't match
      try {
        await program.methods
          .recoverSol(Array.from(recoverOwnerHash) as any)
          .accounts({
            recoverySigner: wrongSigner.publicKey,
            vault: recoverVaultPda, // original vault derived with recovery.publicKey
            recipient: wrongSigner.publicKey,
            portalMeta: recoverMetaPda,
            systemProgram: SystemProgram.programId,
          })
          .signers([wrongSigner])
          .rpc();
        expect.fail("Should have thrown");
      } catch (err: any) {
        // PDA seeds don't match — constraint violation
        expect(err).to.exist;
      }
    });
  });

  describe("recover_spl", () => {
    const recoverSplOwnerHash = Buffer.alloc(32);
    recoverSplOwnerHash.writeUInt32BE(22222, 28);

    let recoverSplVaultPda: PublicKey;
    let recoverSplMetaPda: PublicKey;
    let splMint: PublicKey;
    let splVaultAta: PublicKey;
    const depositAmount = 500_000_000;

    before(async () => {
      [recoverSplVaultPda] = PublicKey.findProgramAddressSync(
        [PORTAL_SEED, recoverSplOwnerHash, recovery.publicKey.toBuffer()],
        program.programId,
      );
      [recoverSplMetaPda] = PublicKey.findProgramAddressSync(
        [
          PORTAL_META_SEED,
          recoverSplOwnerHash,
          recovery.publicKey.toBuffer(),
        ],
        program.programId,
      );

      // Create mint and fund vault ATA
      splMint = await createMint(
        provider.connection,
        authority.payer,
        authority.publicKey,
        null,
        9,
      );

      const ata = await getOrCreateAssociatedTokenAccount(
        provider.connection,
        authority.payer,
        splMint,
        recoverSplVaultPda,
        true,
      );
      splVaultAta = ata.address;

      await mintTo(
        provider.connection,
        authority.payer,
        splMint,
        splVaultAta,
        authority.publicKey,
        depositAmount,
      );

      // Fund recovery signer
      const sig = await provider.connection.requestAirdrop(
        recovery.publicKey,
        LAMPORTS_PER_SOL,
      );
      await provider.connection.confirmTransaction(sig);
    });

    it("recovers SPL tokens and closes ATA", async () => {
      const recipientKp = Keypair.generate();

      // Create recipient token account
      const recipientAta = await getOrCreateAssociatedTokenAccount(
        provider.connection,
        authority.payer,
        splMint,
        recipientKp.publicKey,
      );

      await program.methods
        .recoverSpl(Array.from(recoverSplOwnerHash) as any)
        .accounts({
          recoverySigner: recovery.publicKey,
          vault: recoverSplVaultPda,
          vaultTokenAccount: splVaultAta,
          recipientTokenAccount: recipientAta.address,
          mint: splMint,
          portalMeta: recoverSplMetaPda,
          tokenProgram: TOKEN_PROGRAM_ID,
          associatedTokenProgram: ASSOCIATED_TOKEN_PROGRAM_ID,
          systemProgram: SystemProgram.programId,
        })
        .signers([recovery])
        .rpc();

      // Verify recipient received tokens
      const recipientAccount = await getAccount(
        provider.connection,
        recipientAta.address,
      );
      expect(Number(recipientAccount.amount)).to.equal(depositAmount);

      // Verify vault ATA was closed
      try {
        await getAccount(provider.connection, splVaultAta);
        expect.fail("ATA should have been closed");
      } catch {
        // Expected — account doesn't exist
      }
    });
  });
});
