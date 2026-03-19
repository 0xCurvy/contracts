use anchor_lang::prelude::*;
use anchor_lang::system_program;
use solana_program::secp256k1_recover::secp256k1_recover;
use solana_program::hash::hashv;

use crate::constants::{PORTAL_META_SEED, PORTAL_SEED, SOLANA_RECOVERY_DOMAIN};
use crate::error::PortalError;

/// Recover native SOL from a portal vault.
///
/// Authorization uses Solana's native secp256k1_recover syscall rather than Ed25519
/// signing, because the recovery pubkey is derived from a SECP256k1 stealth key
/// (which cannot be directly used as an Ed25519 signing key).
///
/// The recovery flow:
/// 1. User derives their SECP256k1 stealth private key from their spending/viewing keys
/// 2. User computes msg = SHA-256("curvy-solana-recover" || vault_pubkey || recipient_pubkey)
/// 3. User signs msg with their SECP256k1 stealth key → (sig, rec_id)
/// 4. Program: recovers the SECP256k1 pubkey, compresses it, SHA-256 hashes it with domain tag,
///    and verifies the result equals the recovery_identifier stored in the vault PDA seeds
#[derive(Accounts)]
#[instruction(owner_hash: [u8; 32])]
pub struct RecoverSol<'info> {
    /// Transaction fee payer — any wallet can pay fees (enables relayer pattern)
    #[account(mut)]
    pub payer: Signer<'info>,

    /// CHECK: The 32-byte recovery identifier (SHA-256 of compressed SECP256k1 stealth pubkey).
    /// Not an Ed25519 key — verified below via secp256k1_recover.
    pub recovery_identifier: UncheckedAccount<'info>,

    /// CHECK: Vault PDA holding user's SOL deposit.
    /// Verified by seeds derivation using owner_hash + recovery_identifier.
    #[account(
        mut,
        seeds = [PORTAL_SEED, owner_hash.as_ref(), recovery_identifier.key().as_ref()],
        bump,
    )]
    pub vault: UncheckedAccount<'info>,

    /// CHECK: Any recipient address. Bound into the signed message to prevent front-running.
    #[account(mut)]
    pub recipient: UncheckedAccount<'info>,

    /// Portal metadata PDA (may not exist if portal was never bridged).
    /// CHECK: Validated by seeds if present.
    #[account(
        seeds = [PORTAL_META_SEED, owner_hash.as_ref(), recovery_identifier.key().as_ref()],
        bump,
    )]
    pub portal_meta: UncheckedAccount<'info>,

    pub system_program: Program<'info, System>,
}

pub fn handler(
    ctx: Context<RecoverSol>,
    owner_hash: [u8; 32],
    /// 64-byte SECP256k1 signature (r || s, big-endian)
    secp_sig: [u8; 64],
    /// Recovery ID (0 or 1)
    recovery_id: u8,
) -> Result<()> {
    require!(owner_hash != [0u8; 32], PortalError::InvalidOwnerHash);

    // Build the message the user must have signed:
    // SHA-256("curvy-solana-recover" || vault_pubkey || recipient_pubkey)
    // This binds authorization to a specific vault and recipient — prevents replay and front-running.
    let msg_hash = hashv(&[
        b"curvy-solana-recover",
        ctx.accounts.vault.key().as_ref(),
        ctx.accounts.recipient.key().as_ref(),
    ]);

    // Recover the SECP256k1 public key from the signature
    let recovered = secp256k1_recover(msg_hash.as_ref(), recovery_id, &secp_sig)
        .map_err(|_| PortalError::InvalidSecp256k1Signature)?;

    // Compress the recovered pubkey: 33 bytes = [02/03] + x_coordinate
    // secp256k1_recover returns 64 bytes: x (32 bytes) || y (32 bytes), without 0x04 prefix
    let pubkey_bytes = recovered.0;
    let x_bytes = &pubkey_bytes[..32];
    let y_last_bit = pubkey_bytes[63] & 1;
    let prefix: u8 = if y_last_bit == 0 { 0x02 } else { 0x03 };
    let mut compressed = [0u8; 33];
    compressed[0] = prefix;
    compressed[1..].copy_from_slice(x_bytes);

    // Derive expected recovery identifier: SHA-256(domain_tag || compressed_pubkey)
    let expected = hashv(&[SOLANA_RECOVERY_DOMAIN, &compressed]);

    // Verify the recovered key produces the same identifier stored in the vault PDA seeds
    require!(
        ctx.accounts.recovery_identifier.key().to_bytes() == expected.to_bytes(),
        PortalError::InvalidSecp256k1Signature,
    );

    // Transfer all SOL from vault to recipient
    let vault_lamports = ctx.accounts.vault.lamports();
    require!(vault_lamports > 0, PortalError::InsufficientFunds);

    let owner_hash_ref = owner_hash.as_ref();
    let recovery_key = ctx.accounts.recovery_identifier.key();
    let vault_bump = ctx.bumps.vault;
    let vault_seeds: &[&[u8]] = &[
        PORTAL_SEED,
        owner_hash_ref,
        recovery_key.as_ref(),
        &[vault_bump],
    ];

    system_program::transfer(
        CpiContext::new_with_signer(
            ctx.accounts.system_program.to_account_info(),
            system_program::Transfer {
                from: ctx.accounts.vault.to_account_info(),
                to: ctx.accounts.recipient.to_account_info(),
            },
            &[vault_seeds],
        ),
        vault_lamports,
    )?;

    msg!(
        "Recovered {} lamports from vault {} to {}",
        vault_lamports,
        ctx.accounts.vault.key(),
        ctx.accounts.recipient.key()
    );

    Ok(())
}
