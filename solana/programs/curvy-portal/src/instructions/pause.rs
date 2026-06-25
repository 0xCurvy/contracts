use anchor_lang::prelude::*;

use crate::seeds::CONFIG_SEED;
use crate::error::PortalError;
use crate::events::PauseToggled;
use crate::state::PortalConfig;


pub fn handler(ctx: Context<Pause>, paused: bool) -> Result<()> {
    let config = &mut ctx.accounts.config;
    config.paused = paused;

    emit!(PauseToggled {
        authority: ctx.accounts.authority.key(),
        paused,
    });
    Ok(())
}

#[derive(Accounts)]
pub struct Pause<'info> {
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



