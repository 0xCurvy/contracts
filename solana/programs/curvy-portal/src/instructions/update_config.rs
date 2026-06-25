use anchor_lang::prelude::*;

use crate::seeds::CONFIG_SEED;
use crate::error::PortalError;
use crate::events::{AuthorityUpdated, OperatorUpdated};
use crate::state::PortalConfig;

pub fn handler(
    ctx: Context<UpdateConfig>,
    new_operator: Option<Pubkey>,
    new_authority: Option<Pubkey>,
) -> Result<()> {
    let config = &mut ctx.accounts.config;

    if let Some(operator) = new_operator {
        let old_operator = config.operator;
        config.operator = operator;
        emit!(OperatorUpdated {
            old_operator,
            new_operator: operator,
        });
    }

    if let Some(authority) = new_authority {
        let old_authority = config.authority;
        config.authority = authority;
        emit!(AuthorityUpdated {
            old_authority,
            new_authority: authority,
        });
    }

    Ok(())
}


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


