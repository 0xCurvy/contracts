use anchor_lang::prelude::*;
use anchor_spl::token::spl_token::native_mint;

use crate::error::PortalError;
use crate::events::PortalBridgedSol;
use crate::seeds::{CONFIG_SEED, PORTAL_META_SEED, PORTAL_SEED};
use crate::state::{PortalAccount, PortalConfig};

pub fn handler(
    ctx: Context<BridgeRelaySol>,
    owner_hash: [u8; 32],
    recovery_identifier: [u8; 32],
    input_amount: u64,
    relay_id: [u8; 32],
) -> Result<()> {
    require!(input_amount > 0, PortalError::InsufficientFunds);

    let rent = Rent::get()?;
    let min_vault_rent = rent.minimum_balance(0);
    let vault_lamports = ctx.accounts.vault.lamports();
    require!(
        vault_lamports
            >= min_vault_rent
                .checked_add(input_amount)
                .ok_or(PortalError::InsufficientFunds)?,
        PortalError::InsufficientFunds
    );

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

    let cpi_accounts = crate::relay_depository::cpi::accounts::DepositNative {
        relay_depository: ctx.accounts.relay_depository.to_account_info(),
        sender: ctx.accounts.vault.to_account_info(),
        depositor: ctx.accounts.vault.to_account_info(),
        vault: ctx.accounts.relay_vault.to_account_info(),
        system_program: ctx.accounts.system_program.to_account_info(),
    };
    let cpi_ctx = CpiContext::new_with_signer(
        ctx.accounts.relay_program.to_account_info(),
        cpi_accounts,
        &signer_seeds,
    );
    crate::relay_depository::cpi::deposit_native(cpi_ctx, input_amount, relay_id)?;

    let portal = &mut ctx.accounts.portal;
    let clock = Clock::get()?;
    portal.owner_hash = owner_hash;
    portal.recovery_identifier = recovery_identifier;
    portal.is_used = true;
    portal.created_at = clock.unix_timestamp;
    portal.amount_withdrawn = input_amount;
    portal.currency_mint = native_mint::ID;
    portal.bump = ctx.bumps.portal;
    portal.vault_bump = vault_bump;

    emit!(PortalBridgedSol {
        owner_hash,
        recovery_identifier: recovery_identifier,
        portal: portal.key(),
        vault: ctx.accounts.vault.key(),
        operator: ctx.accounts.operator.key(),
        lamports: input_amount,
        created_at: portal.created_at,
        currency_mint: portal.currency_mint,
        portal_bump: portal.bump,
        vault_bump: portal.vault_bump,
        destination_chain_id: ctx.accounts.config.destination_chain_id,
    });

    Ok(())
}

#[derive(Accounts)]
#[instruction(owner_hash: [u8; 32], recovery_identifier: [u8; 32], input_amount: u64, relay_id: [u8; 32])]
pub struct BridgeRelaySol<'info> {
    #[account(
        mut,
        constraint = operator.key() == config.operator @ PortalError::UnauthorizedOperator,
    )]
    pub operator: Signer<'info>,

    #[account(
        seeds = [CONFIG_SEED],
        bump = config.bump,
        constraint = !config.paused @ PortalError::Paused,
    )]
    pub config: Account<'info, PortalConfig>,

    #[account(
        init,
        payer = operator,
        space = 8 + PortalAccount::INIT_SPACE,
        seeds = [PORTAL_META_SEED, owner_hash.as_ref(), recovery_identifier.as_ref()],
        bump,
    )]
    pub portal: Account<'info, PortalAccount>,

    /// CHECK: Portal vault PDA; signer for Relay `deposit_native` CPI.
    #[account(
        mut,
        seeds = [PORTAL_SEED, owner_hash.as_ref(), recovery_identifier.as_ref()],
        bump,
        constraint = owner_hash != [0u8; 32] @ PortalError::InvalidOwnerHash,
        constraint = vault.lamports() > 0 @ PortalError::InsufficientFunds,
    )]
    pub vault: UncheckedAccount<'info>,

    /// CHECK: Relay depository program from IDL.
    #[account(address = crate::relay_depository::ID_CONST)]
    pub relay_program: AccountInfo<'info>,

    /// CHECK: Relay depository PDA (see relay_depository IDL).
    #[account(mut)]
    pub relay_depository: AccountInfo<'info>,

    /// CHECK: Relay vault PDA that receives native SOL (see relay_depository IDL).
    #[account(mut)]
    pub relay_vault: AccountInfo<'info>,

    pub system_program: Program<'info, System>,
}
