use anchor_lang::prelude::*;
use anchor_spl::associated_token::AssociatedToken;

use anchor_spl::token::{self, CloseAccount, Mint, Token, TokenAccount, Transfer};

use crate::recovery;
use crate::seeds::{PORTAL_META_SEED, PORTAL_SEED};
use crate::error::PortalError;
use crate::events::PortalRecoveredSpl;

pub fn handler(
    ctx: Context<RecoverSpl>,
    owner_hash: [u8; 32],
    recovery_identifier: [u8; 32],
    recovery_id: u8,
    signature: [u8; 64],
) -> Result<()> {
    recovery::verify_spl_recovery(
        ctx.program_id,
        &owner_hash,
        &recovery_identifier,
        &ctx.accounts.recipient.key(),
        &ctx.accounts.mint.key(),
        &signature,
        recovery_id,
    )?;

    

    let token_balance = ctx.accounts.vault_token_account.amount;

    let owner_hash_ref = owner_hash.as_ref();
    let recovery_id_ref = recovery_identifier.as_ref();
    let vault_bump = ctx.bumps.vault;
    let vault_bump_seed = [vault_bump];
    let vault_seeds: &[&[u8]] = &[
        PORTAL_SEED,
        owner_hash_ref,
        recovery_id_ref,
        &vault_bump_seed,
    ];
    let signer_seeds = [vault_seeds];

    token::transfer(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            Transfer {
                from: ctx.accounts.vault_token_account.to_account_info(),
                to: ctx.accounts.recipient_token_account.to_account_info(),
                authority: ctx.accounts.vault.to_account_info(),
            },
            &signer_seeds,
        ),
        token_balance,
    )?;

    token::close_account(CpiContext::new_with_signer(
        ctx.accounts.token_program.to_account_info(),
        CloseAccount {
            account: ctx.accounts.vault_token_account.to_account_info(),
            destination: ctx.accounts.payer.to_account_info(),
            authority: ctx.accounts.vault.to_account_info(),
        },
        &signer_seeds,
    ))?;

    emit!(PortalRecoveredSpl {
        owner_hash,
        recovery_identifier: recovery_identifier,
        vault: ctx.accounts.vault.key(),
        vault_token_account: ctx.accounts.vault_token_account.key(),
        recipient_token_account: ctx.accounts.recipient_token_account.key(),
        recipient: ctx.accounts.recipient.key(),
        mint: ctx.accounts.mint.key(),
        tokens: token_balance,
        vault_bump: ctx.bumps.vault,
    });

    Ok(())
}

#[derive(Accounts)]
#[instruction(owner_hash: [u8; 32], recovery_identifier: [u8; 32], recovery_id: u8, signature: [u8; 64])]
pub struct RecoverSpl<'info> {
    #[account(mut)]
    pub payer: Signer<'info>,

    /// CHECK: Vault PDA — authority for the vault token account.
    #[account(
        seeds = [PORTAL_SEED, owner_hash.as_ref(), recovery_identifier.as_ref()],
        bump,
        constraint = owner_hash != [0u8; 32] @ PortalError::InvalidOwnerHash,
    )]
    pub vault: UncheckedAccount<'info>,

    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = vault,
        constraint = vault_token_account.amount > 0 @ PortalError::EmptyVaultTokenAccount,
    )]
    pub vault_token_account: Account<'info, TokenAccount>,

    #[account(
        mut,
        token::mint = mint,
    )]
    pub recipient_token_account: Account<'info, TokenAccount>,

    /// CHECK: Bound into signed message hash.
    pub recipient: UncheckedAccount<'info>,

    pub mint: Account<'info, Mint>,

    /// CHECK: Portal metadata PDA (same seeds as vault).
    #[account(
        seeds = [PORTAL_META_SEED, owner_hash.as_ref(), recovery_identifier.as_ref()],
        bump,
    )]
    pub portal_meta: UncheckedAccount<'info>,

    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}
