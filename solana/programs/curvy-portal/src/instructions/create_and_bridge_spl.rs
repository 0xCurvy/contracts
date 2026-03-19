use anchor_lang::prelude::*;
use anchor_spl::associated_token::AssociatedToken;
use anchor_spl::token::{self, Mint, Token, TokenAccount, Transfer};

use crate::constants::{CONFIG_SEED, PORTAL_META_SEED, PORTAL_SEED};
use crate::error::PortalError;
use crate::state::{PortalAccount, PortalConfig};

#[derive(Accounts)]
#[instruction(owner_hash: [u8; 32])]
pub struct CreateAndBridgeSpl<'info> {
    /// Backend operator — must match config.operator
    #[account(
        mut,
        constraint = operator.key() == config.operator @ PortalError::UnauthorizedOperator,
    )]
    pub operator: Signer<'info>,

    #[account(
        seeds = [CONFIG_SEED],
        bump = config.bump,
    )]
    pub config: Account<'info, PortalConfig>,

    /// Portal metadata account — created on first bridge, prevents re-use
    #[account(
        init,
        payer = operator,
        space = 8 + PortalAccount::INIT_SPACE,
        seeds = [PORTAL_META_SEED, owner_hash.as_ref(), recovery.key().as_ref()],
        bump,
    )]
    pub portal: Account<'info, PortalAccount>,

    /// CHECK: Vault PDA — authority for the vault token account.
    /// Verified by seeds derivation.
    #[account(
        seeds = [PORTAL_SEED, owner_hash.as_ref(), recovery.key().as_ref()],
        bump,
    )]
    pub vault: UncheckedAccount<'info>,

    /// Vault's associated token account holding deposited SPL tokens
    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = vault,
    )]
    pub vault_token_account: Account<'info, TokenAccount>,

    /// Operator's token account to receive funds for bridging
    #[account(
        mut,
        token::mint = mint,
    )]
    pub destination_token_account: Account<'info, TokenAccount>,

    pub mint: Account<'info, Mint>,

    /// CHECK: Recovery pubkey — part of PDA derivation.
    pub recovery: UncheckedAccount<'info>,

    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}

pub fn handler(ctx: Context<CreateAndBridgeSpl>, owner_hash: [u8; 32]) -> Result<()> {
    require!(owner_hash != [0u8; 32], PortalError::InvalidOwnerHash);

    let token_balance = ctx.accounts.vault_token_account.amount;
    require!(token_balance > 0, PortalError::EmptyVaultTokenAccount);

    // Transfer SPL tokens from vault ATA to operator's token account
    let owner_hash_ref = owner_hash.as_ref();
    let recovery_key = ctx.accounts.recovery.key();
    let vault_bump = ctx.bumps.vault;
    let vault_seeds: &[&[u8]] = &[
        PORTAL_SEED,
        owner_hash_ref,
        recovery_key.as_ref(),
        &[vault_bump],
    ];

    token::transfer(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            Transfer {
                from: ctx.accounts.vault_token_account.to_account_info(),
                to: ctx.accounts.destination_token_account.to_account_info(),
                authority: ctx.accounts.vault.to_account_info(),
            },
            &[vault_seeds],
        ),
        token_balance,
    )?;

    // Initialize portal metadata
    let portal = &mut ctx.accounts.portal;
    let clock = Clock::get()?;

    portal.owner_hash = owner_hash;
    portal.recovery = ctx.accounts.recovery.key();
    portal.is_used = true;
    portal.created_at = clock.unix_timestamp;
    portal.amount_withdrawn = token_balance;
    portal.currency_mint = ctx.accounts.mint.key();
    portal.bump = ctx.bumps.portal;
    portal.vault_bump = vault_bump;

    msg!(
        "Portal bridged: {} tokens ({}) from vault {} to operator",
        token_balance,
        ctx.accounts.mint.key(),
        ctx.accounts.vault.key()
    );

    Ok(())
}
