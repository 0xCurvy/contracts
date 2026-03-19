use anchor_lang::prelude::*;

use crate::constants::CONFIG_SEED;
use crate::error::PortalError;
use crate::state::PortalConfig;

#[derive(Accounts)]
pub struct UpdateConfig<'info> {
    #[account(
        constraint = authority.key() == config.authority @ PortalError::UnauthorizedAuthority,
    )]
    pub authority: Signer<'info>,

    #[account(
        mut,
        seeds = [CONFIG_SEED],
        bump = config.bump,
    )]
    pub config: Account<'info, PortalConfig>,
}

pub fn handler(
    ctx: Context<UpdateConfig>,
    new_operator: Option<Pubkey>,
    new_authority: Option<Pubkey>,
) -> Result<()> {
    let config = &mut ctx.accounts.config;

    if let Some(operator) = new_operator {
        config.operator = operator;
        msg!("Operator updated to: {}", operator);
    }

    if let Some(authority) = new_authority {
        config.authority = authority;
        msg!("Authority updated to: {}", authority);
    }

    Ok(())
}
