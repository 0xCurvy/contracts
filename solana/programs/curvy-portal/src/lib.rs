use anchor_lang::prelude::*;


pub mod across_bridge;
pub use across_bridge::{evm_address_to_pubkey, output_amount_bytes32, AcrossBridgeQuoteParams};
pub mod seeds;
pub mod recovery;
pub mod error;
pub mod instructions;
pub mod events;
pub mod state;

use instructions::*;

declare_id!("6cHtg7sPLL9NQQuuyepnkud6PskMWV5yxvU2vXfag4qX");
declare_program!(across);
declare_program!(relay_depository);

#[program]
pub mod curvy_portal {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>, operator: Pubkey) -> Result<()> {
        instructions::initialize::handler(ctx, operator)
    }

    pub fn update_config(
        ctx: Context<UpdateConfig>,
        new_operator: Option<Pubkey>,
        new_authority: Option<Pubkey>,
    ) -> Result<()> {
        instructions::update_config::handler(ctx, new_operator, new_authority)
    }

    pub fn pause(ctx: Context<Pause>, paused: bool) -> Result<()> {
        instructions::pause::handler(ctx, paused)?;
        Ok(())
    }

    /// Admin/operator: prepare deterministic SOL vault PDA (stealth address).
    pub fn create_stealth_sol(
        ctx: Context<CreateStealthSol>,
        owner_hash: [u8; 32],
        recovery_identifier: [u8; 32],
    ) -> Result<()> {
        instructions::create_stealth_sol::handler(ctx, owner_hash, recovery_identifier)
    }

    /// Admin/operator: create vault ATA for SPL if needed.
    pub fn create_stealth_spl_ata(
        ctx: Context<CreateStealthSplAta>,
        owner_hash: [u8; 32],
        recovery_identifier: [u8; 32],
    ) -> Result<()> {
        instructions::create_stealth_spl_ata::handler(ctx, owner_hash, recovery_identifier)
    }

    /// Admin/operator: wrap vault SOL to WSOL then CPI Across `deposit` (quote params from LiFi / Across API).
    pub fn bridge_sol(
        ctx: Context<BridgeSol>,
        owner_hash: [u8; 32],
        recovery_identifier: [u8; 32],
        input_amount: u64,
        across_state_seed: u64,
        quote: AcrossBridgeQuoteParams,
    ) -> Result<()> {
        instructions::bridge_across_sol::handler(
            ctx,
            owner_hash,
            recovery_identifier,
            input_amount,
            across_state_seed,
            quote,
        )
    }

    /// Admin/operator: CPI Across `deposit` from vault ATA (full balance must match `input_amount`).
    pub fn bridge_spl(
        ctx: Context<BridgeSpl>,
        owner_hash: [u8; 32],
        recovery_identifier: [u8; 32],
        input_amount: u64,
        across_state_seed: u64,
        quote: AcrossBridgeQuoteParams,
    ) -> Result<()> {
        instructions::bridge_across_spl::handler(
            ctx,
            owner_hash,
            recovery_identifier,
            input_amount,
            across_state_seed,
            quote,
        )
    }

    pub fn bridge_relay_sol<'info>(
        ctx: Context<'_, '_, '_, 'info, BridgeRelaySol<'info>>,
        owner_hash: [u8; 32],
        recovery_identifier: [u8; 32],
        input_amount: u64,
        relay_amount: u64,
        fee_amounts: Vec<u64>,
        relay_id: [u8; 32],
    ) -> Result<()> {
        instructions::bridge_relay_sol::handler(
            ctx,
            owner_hash,
            recovery_identifier,
            input_amount,
            relay_amount,
            fee_amounts,
            relay_id,
        )
    }

    pub fn bridge_relay_spl<'info>(
        ctx: Context<'_, '_, '_, 'info, BridgeRelaySpl<'info>>,
        owner_hash: [u8; 32],
        recovery_identifier: [u8; 32],
        input_amount: u64,
        relay_amount: u64,
        fee_amounts: Vec<u64>,
        relay_id: [u8; 32],
    ) -> Result<()> {
        instructions::bridge_relay_spl::handler(
            ctx,
            owner_hash,
            recovery_identifier,
            input_amount,
            relay_amount,
            fee_amounts,
            relay_id,
        )
    }

    /// Admin/operator: execute an amount-checked Eco LiFi SPL route from the vault ATA.
    pub fn bridge_eco_spl<'info>(
        ctx: Context<'_, '_, '_, 'info, BridgeEcoSpl<'info>>,
        owner_hash: [u8; 32],
        recovery_identifier: [u8; 32],
        input_amount: u64,
        provider_amount: u64,
        fee_amounts: Vec<u64>,
        provider_instruction_data: Vec<u8>,
    ) -> Result<()> {
        instructions::bridge_eco_spl::handler(
            ctx,
            owner_hash,
            recovery_identifier,
            input_amount,
            provider_amount,
            fee_amounts,
            provider_instruction_data,
        )
    }

    pub fn recover_sol(
        ctx: Context<RecoverSol>,
        owner_hash: [u8; 32],
        recovery_identifier: [u8; 32],
        recovery_id: u8,
        signature: [u8; 64],
    ) -> Result<()> {
        instructions::recover_sol::handler(ctx, owner_hash, recovery_identifier, recovery_id, signature)?;
        Ok(())
    }

    pub fn recover_spl(
        ctx: Context<RecoverSpl>,
        owner_hash: [u8; 32],
        recovery_identifier: [u8; 32],
        recovery_id: u8,
        signature: [u8; 64],
    ) -> Result<()> {
        instructions::recover_spl::handler(ctx, owner_hash, recovery_identifier, recovery_id, signature)?;
        Ok(())
    }
}
