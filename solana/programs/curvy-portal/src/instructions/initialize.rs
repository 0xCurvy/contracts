use anchor_lang::prelude::*;

use crate::seeds::{ARBITRUM_CHAIN_ID, CONFIG_SEED};
use crate::events::PortalConfigInitialized;
use crate::state::PortalConfig;

pub fn handler(ctx: Context<Initialize>, operator: Pubkey) -> Result<()> {
    let config = &mut ctx.accounts.config;
    config.authority = ctx.accounts.authority.key();
    config.operator = operator;
    config.paused = false;
    config.destination_chain_id = ARBITRUM_CHAIN_ID;
    config.bump = ctx.bumps.config;

    emit!(PortalConfigInitialized {
        authority: config.authority,
        operator: config.operator,
        paused: config.paused,
        destination_chain_id: config.destination_chain_id,
    });

    Ok(())
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(mut)]
    pub authority: Signer<'info>,

    #[account(
        init,
        payer = authority,
        space = 8 + PortalConfig::INIT_SPACE,
        seeds = [CONFIG_SEED],
        bump,
    )]
    pub config: Account<'info, PortalConfig>,

    pub system_program: Program<'info, System>,
}
