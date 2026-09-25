use anchor_lang::prelude::*;

#[account]
#[derive(InitSpace)]
pub struct PortalConfig {
    /// Admin authority that can update config
    pub authority: Pubkey,
    /// Backend operator wallet — calls create_and_bridge and receives withdrawn funds
    pub operator: Pubkey,
    /// When true, new bridge/withdraw flows are paused (admin can toggle).
    pub paused: bool,
    /// Destination chain ID for bridging (42161 = Arbitrum)
    pub destination_chain_id: u64,
    /// PDA bump seed
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct PortalAccount {
    /// Owner hash matching EVM uint256 ownerHash (Poseidon hash)
    pub owner_hash: [u8; 32],
    /// `SHA256(domain || compressed_secp256k1_pubkey)` — same 32-byte id as in vault PDA seeds
    pub recovery_identifier: [u8; 32],
    /// Whether bridge has been executed (onlyOnce equivalent)
    pub is_used: bool,
    /// Timestamp when portal was created/bridged
    pub created_at: i64,
    /// Amount withdrawn for bridging
    pub amount_withdrawn: u64,
    /// Token mint (Pubkey::default() for native SOL)
    pub currency_mint: Pubkey,
    /// Bump for the portal metadata PDA
    pub bump: u8,
    /// Bump for the vault PDA
    pub vault_bump: u8,
}
