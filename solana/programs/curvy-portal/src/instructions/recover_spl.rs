use anchor_lang::prelude::*;
use anchor_spl::associated_token::AssociatedToken;
use anchor_spl::token::{self, CloseAccount, Mint, Token, TokenAccount, Transfer};
use solana_program::secp256k1_recover::secp256k1_recover;
use solana_program::hash::hashv;

use crate::constants::{PORTAL_META_SEED, PORTAL_SEED, SOLANA_RECOVERY_DOMAIN};
use crate::error::PortalError;

/// Recover SPL tokens from a portal vault's ATA.
/// Uses the same secp256k1 verification scheme as recover_sol.
/// Closes the empty vault ATA after transfer, returning rent to the payer.
#[derive(Accounts)]
#[instruction(owner_hash: [u8; 32])]
pub struct RecoverSpl<'info> {
    /// Transaction fee payer — any wallet can pay fees (enables relayer pattern)
    #[account(mut)]
    pub payer: Signer<'info>,

    /// CHECK: The 32-byte recovery identifier (SHA-256 of compressed SECP256k1 stealth pubkey).
    pub recovery_identifier: UncheckedAccount<'info>,

    /// CHECK: Vault PDA — authority for the vault token account.
    #[account(
        seeds = [PORTAL_SEED, owner_hash.as_ref(), recovery_identifier.key().as_ref()],
        bump,
    )]
    pub vault: UncheckedAccount<'info>,

    /// Vault's associated token account
    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = vault,
    )]
    pub vault_token_account: Account<'info, TokenAccount>,

    /// Recipient's token account
    #[account(
        mut,
        token::mint = mint,
    )]
    pub recipient_token_account: Account<'info, TokenAccount>,

    /// CHECK: Any recipient address. Bound into the signed message to prevent front-running.
    pub recipient: UncheckedAccount<'info>,

    pub mint: Account<'info, Mint>,

    /// Portal metadata (optional — may not exist).
    /// CHECK: Validated by seeds if present.
    #[account(
        seeds = [PORTAL_META_SEED, owner_hash.as_ref(), recovery_identifier.key().as_ref()],
        bump,
    )]
    pub portal_meta: UncheckedAccount<'info>,

    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}

pub fn handler(
    ctx: Context<RecoverSpl>,
    owner_hash: [u8; 32],
    secp_sig: [u8; 64],
    recovery_id: u8,
) -> Result<()> {
    require!(owner_hash != [0u8; 32], PortalError::InvalidOwnerHash);

    // Build recovery message (same structure as recover_sol)
    let msg_hash = hashv(&[
        b"curvy-solana-recover",
        ctx.accounts.vault.key().as_ref(),
        ctx.accounts.recipient.key().as_ref(),
    ]);

    // Recover SECP256k1 pubkey from signature
    let recovered = secp256k1_recover(msg_hash.as_ref(), recovery_id, &secp_sig)
        .map_err(|_| PortalError::InvalidSecp256k1Signature)?;

    // Compress recovered pubkey
    let pubkey_bytes = recovered.0;
    let x_bytes = &pubkey_bytes[..32];
    let y_last_bit = pubkey_bytes[63] & 1;
    let prefix: u8 = if y_last_bit == 0 { 0x02 } else { 0x03 };
    let mut compressed = [0u8; 33];
    compressed[0] = prefix;
    compressed[1..].copy_from_slice(x_bytes);

    // Derive expected recovery identifier and verify
    let expected = hashv(&[SOLANA_RECOVERY_DOMAIN, &compressed]);
    require!(
        ctx.accounts.recovery_identifier.key().to_bytes() == expected.to_bytes(),
        PortalError::InvalidSecp256k1Signature,
    );

    let token_balance = ctx.accounts.vault_token_account.amount;
    require!(token_balance > 0, PortalError::EmptyVaultTokenAccount);

    let owner_hash_ref = owner_hash.as_ref();
    let recovery_key = ctx.accounts.recovery_identifier.key();
    let vault_bump = ctx.bumps.vault;
    let vault_seeds: &[&[u8]] = &[
        PORTAL_SEED,
        owner_hash_ref,
        recovery_key.as_ref(),
        &[vault_bump],
    ];

    // Transfer all SPL tokens to recipient
    token::transfer(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            Transfer {
                from: ctx.accounts.vault_token_account.to_account_info(),
                to: ctx.accounts.recipient_token_account.to_account_info(),
                authority: ctx.accounts.vault.to_account_info(),
            },
            &[vault_seeds],
        ),
        token_balance,
    )?;

    // Close the empty vault ATA — rent goes back to payer
    token::close_account(CpiContext::new_with_signer(
        ctx.accounts.token_program.to_account_info(),
        CloseAccount {
            account: ctx.accounts.vault_token_account.to_account_info(),
            destination: ctx.accounts.payer.to_account_info(),
            authority: ctx.accounts.vault.to_account_info(),
        },
        &[vault_seeds],
    ))?;

    msg!(
        "Recovered {} tokens ({}) from vault {} to {}",
        token_balance,
        ctx.accounts.mint.key(),
        ctx.accounts.vault.key(),
        ctx.accounts.recipient_token_account.key()
    );

    Ok(())
}
