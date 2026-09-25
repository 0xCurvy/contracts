use anchor_lang::prelude::*;
use anchor_lang::solana_program::system_program::ID as SYSTEM_PROGRAM_ID;
use anchor_lang::system_program;

use crate::error::PortalError;
use crate::events::StealthSolVaultPrepared;
use crate::seeds::{CONFIG_SEED, PORTAL_SEED};
use crate::state::PortalConfig;

pub fn handler(
    ctx: Context<CreateStealthSol>,
    owner_hash: [u8; 32],
    recovery_identifier: [u8; 32],
) -> Result<()> {
    let vault_ai = ctx.accounts.vault.to_account_info();
    let min_rent = Rent::get()?.minimum_balance(0);

    if vault_ai.lamports() == 0 {
        let bump = ctx.bumps.vault;
        let seeds: &[&[u8]] = &[
            PORTAL_SEED,
            owner_hash.as_ref(),
            recovery_identifier.as_ref(),
            &[bump],
        ];
        let signer_seeds = &[seeds];

        let cpi_accounts = system_program::CreateAccount {
            from: ctx.accounts.operator.to_account_info(),
            to: ctx.accounts.vault.to_account_info(),
        };
        let cpi_ctx = CpiContext::new_with_signer(
            ctx.accounts.system_program.to_account_info(),
            cpi_accounts,
            signer_seeds,
        );
        system_program::create_account(cpi_ctx, min_rent, 0, &SYSTEM_PROGRAM_ID)?;
    } else {
        require!(
            vault_ai.owner == &SYSTEM_PROGRAM_ID,
            PortalError::InvalidVaultOwner
        );
    }

    emit!(StealthSolVaultPrepared {
        owner_hash,
        recovery_identifier: recovery_identifier,
        vault: ctx.accounts.vault.key(),
    });

    Ok(())
}

#[derive(Accounts)]
#[instruction(owner_hash: [u8; 32], recovery_identifier: [u8; 32])]
pub struct CreateStealthSol<'info> {
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

    /// CHECK: System-owned vault PDA — seeds include `recovery_identifier` (SHA256(domain||secp pubkey)).
    #[account(
        mut,
        seeds = [PORTAL_SEED, owner_hash.as_ref(), recovery_identifier.as_ref()],
        bump,
        constraint = owner_hash != [0u8; 32] @ PortalError::InvalidOwnerHash,
    )]
    pub vault: UncheckedAccount<'info>,

    pub system_program: Program<'info, System>,
}
