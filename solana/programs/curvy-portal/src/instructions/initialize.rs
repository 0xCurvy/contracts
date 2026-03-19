use anchor_lang::prelude::*;

use crate::constants::{ARBITRUM_CHAIN_ID, CONFIG_SEED};
use crate::state::PortalConfig;

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

pub fn handler(ctx: Context<Initialize>, operator: Pubkey) -> Result<()> {
    let config = &mut ctx.accounts.config;
    config.authority = ctx.accounts.authority.key();
    config.operator = operator;
    config.destination_chain_id = ARBITRUM_CHAIN_ID;
    config.bump = ctx.bumps.config;

    msg!(
        "Portal config initialized. Authority: {}, Operator: {}, Destination chain: {}",
        config.authority,
        config.operator,
        config.destination_chain_id
    );

    Ok(())
}
