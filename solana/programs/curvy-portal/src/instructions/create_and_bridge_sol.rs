use anchor_lang::prelude::*;
use anchor_lang::system_program;

use crate::constants::{CONFIG_SEED, PORTAL_META_SEED, PORTAL_SEED};
use crate::error::PortalError;
use crate::state::{PortalAccount, PortalConfig};

#[derive(Accounts)]
#[instruction(owner_hash: [u8; 32])]
pub struct CreateAndBridgeSol<'info> {
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

    /// Portal metadata account — created on first bridge, prevents re-use via init constraint
    #[account(
        init,
        payer = operator,
        space = 8 + PortalAccount::INIT_SPACE,
        seeds = [PORTAL_META_SEED, owner_hash.as_ref(), recovery.key().as_ref()],
        bump,
    )]
    pub portal: Account<'info, PortalAccount>,

    /// CHECK: Vault PDA that holds the user's SOL deposit.
    /// System Program-owned (never initialized as a data account).
    /// Verified by seeds derivation.
    #[account(
        mut,
        seeds = [PORTAL_SEED, owner_hash.as_ref(), recovery.key().as_ref()],
        bump,
    )]
    pub vault: UncheckedAccount<'info>,

    /// CHECK: Recovery pubkey — part of PDA derivation, not validated beyond that.
    pub recovery: UncheckedAccount<'info>,

    /// Operator's wallet where SOL is transferred for subsequent LiFi bridging
    /// CHECK: Validated to match config.operator
    #[account(
        mut,
        constraint = destination.key() == config.operator @ PortalError::InvalidDestination,
    )]
    pub destination: UncheckedAccount<'info>,

    pub system_program: Program<'info, System>,
}

pub fn handler(ctx: Context<CreateAndBridgeSol>, owner_hash: [u8; 32]) -> Result<()> {
    // Validate owner_hash is non-zero
    require!(owner_hash != [0u8; 32], PortalError::InvalidOwnerHash);

    let vault = &ctx.accounts.vault;
    let vault_lamports = vault.lamports();

    // Must have more than rent-exempt minimum (0 for uninitialized = all available)
    require!(vault_lamports > 0, PortalError::InsufficientFunds);

    // Transfer all SOL from vault PDA to operator destination
    let owner_hash_ref = owner_hash.as_ref();
    let recovery_key = ctx.accounts.recovery.key();
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
                to: ctx.accounts.destination.to_account_info(),
            },
            &[vault_seeds],
        ),
        vault_lamports,
    )?;

    // Initialize portal metadata
    let portal = &mut ctx.accounts.portal;
    let clock = Clock::get()?;

    portal.owner_hash = owner_hash;
    portal.recovery = ctx.accounts.recovery.key();
    portal.is_used = true;
    portal.created_at = clock.unix_timestamp;
    portal.amount_withdrawn = vault_lamports;
    portal.currency_mint = Pubkey::default(); // native SOL
    portal.bump = ctx.bumps.portal;
    portal.vault_bump = vault_bump;

    msg!(
        "Portal bridged: {} lamports from vault {} to operator {}",
        vault_lamports,
        ctx.accounts.vault.key(),
        ctx.accounts.destination.key()
    );

    Ok(())
}
