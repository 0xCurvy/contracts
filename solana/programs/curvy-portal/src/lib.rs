use anchor_lang::prelude::*;

pub mod constants;
pub mod error;
pub mod instructions;
pub mod state;

use instructions::*;

declare_id!("5YHYjrHecckQdqdF9iEmkfcLj5s73RSUS7uiLJvvA9nP");

#[program]
pub mod curvy_portal {
    use super::*;

    /// Initialize the global portal config. Called once after deployment.
    pub fn initialize(ctx: Context<Initialize>, operator: Pubkey) -> Result<()> {
        instructions::initialize::handler(ctx, operator)
    }

    /// Update the portal config (operator, authority). Authority-only.
    pub fn update_config(
        ctx: Context<UpdateConfig>,
        new_operator: Option<Pubkey>,
        new_authority: Option<Pubkey>,
    ) -> Result<()> {
        instructions::update_config::handler(ctx, new_operator, new_authority)
    }

    /// Initialize a portal and withdraw native SOL from the vault PDA to the operator.
    /// The operator then bridges these funds to Arbitrum via LiFi in the same transaction.
    pub fn create_and_bridge_sol(
        ctx: Context<CreateAndBridgeSol>,
        owner_hash: [u8; 32],
    ) -> Result<()> {
        instructions::create_and_bridge_sol::handler(ctx, owner_hash)
    }

    /// Initialize a portal and withdraw SPL tokens from the vault PDA's ATA to the operator.
    /// The operator then bridges these funds to Arbitrum via LiFi in the same transaction.
    pub fn create_and_bridge_spl(
        ctx: Context<CreateAndBridgeSpl>,
        owner_hash: [u8; 32],
    ) -> Result<()> {
        instructions::create_and_bridge_spl::handler(ctx, owner_hash)
    }

    /// Recover native SOL from a portal vault.
    /// Authorization is proved via a SECP256k1 signature over a bound message
    /// (vault + recipient pubkeys), verified on-chain using Solana's secp256k1_recover syscall.
    /// Works whether the portal has been initialized (bridged) or not.
    pub fn recover_sol(
        ctx: Context<RecoverSol>,
        owner_hash: [u8; 32],
        secp_sig: [u8; 64],
        recovery_id: u8,
    ) -> Result<()> {
        instructions::recover_sol::handler(ctx, owner_hash, secp_sig, recovery_id)
    }

    /// Recover SPL tokens from a portal vault's ATA.
    /// Same secp256k1 authorization as recover_sol.
    /// Closes the empty ATA after transfer, returning rent to the payer.
    pub fn recover_spl(
        ctx: Context<RecoverSpl>,
        owner_hash: [u8; 32],
        secp_sig: [u8; 64],
        recovery_id: u8,
    ) -> Result<()> {
        instructions::recover_spl::handler(ctx, owner_hash, secp_sig, recovery_id)
    }
}
