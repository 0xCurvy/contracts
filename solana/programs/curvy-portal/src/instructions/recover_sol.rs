use anchor_lang::prelude::*;
use anchor_lang::system_program;

use crate::recovery;
use crate::seeds::{PORTAL_META_SEED, PORTAL_SEED};
use crate::error::PortalError;
use crate::events::PortalRecoveredSol;

pub fn handler(
    ctx: Context<RecoverSol>,
    owner_hash: [u8; 32],
    recovery_identifier: [u8; 32],
    recovery_id: u8,
    signature: [u8; 64],
) -> Result<()> {
    recovery::verify_sol_recovery(
        ctx.program_id,
        &owner_hash,
        &recovery_identifier,
        &ctx.accounts.recipient.key(),
        &signature,
        recovery_id,
    )?;

    let vault_lamports = ctx.accounts.vault.lamports();
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

    system_program::transfer(
        CpiContext::new_with_signer(
            ctx.accounts.system_program.to_account_info(),
            system_program::Transfer {
                from: ctx.accounts.vault.to_account_info(),
                to: ctx.accounts.recipient.to_account_info(),
            },
            &signer_seeds,
        ),
        vault_lamports,
    )?;

    emit!(PortalRecoveredSol {
        owner_hash,
        recovery_identifier: recovery_identifier,
        vault: ctx.accounts.vault.key(),
        recipient: ctx.accounts.recipient.key(),
        lamports: vault_lamports,
        vault_bump: ctx.bumps.vault,
    });

    Ok(())
}

#[derive(Accounts)]
#[instruction(owner_hash: [u8; 32], recovery_identifier: [u8; 32], recovery_id: u8, signature: [u8; 64])]
pub struct RecoverSol<'info> {
    #[account(mut)]
    pub payer: Signer<'info>,

    /// CHECK: Vault PDA holding user's SOL deposit.
    #[account(
        mut,
        seeds = [PORTAL_SEED, owner_hash.as_ref(), recovery_identifier.as_ref()],
        bump,
        constraint = owner_hash != [0u8; 32] @ PortalError::InvalidOwnerHash,
        constraint = vault.lamports() > 0 @ PortalError::InsufficientFunds,
    )]
    pub vault: UncheckedAccount<'info>,

    /// CHECK: Any recipient address — bound into the signed message hash.
    #[account(mut)]
    pub recipient: UncheckedAccount<'info>,

    /// CHECK: Portal metadata PDA (same seeds as vault).
    #[account(
        seeds = [PORTAL_META_SEED, owner_hash.as_ref(), recovery_identifier.as_ref()],
        bump,
    )]
    pub portal_meta: UncheckedAccount<'info>,

    pub system_program: Program<'info, System>,
}
