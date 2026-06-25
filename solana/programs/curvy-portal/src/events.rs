use anchor_lang::prelude::*;

#[event]
pub struct PortalConfigInitialized {
    pub authority: Pubkey,
    pub operator: Pubkey,
    pub paused: bool,
    pub destination_chain_id: u64,
}

#[event]
pub struct OperatorUpdated {
    pub old_operator: Pubkey,
    pub new_operator: Pubkey,
}

#[event]
pub struct AuthorityUpdated {
    pub old_authority: Pubkey,
    pub new_authority: Pubkey,
}

#[event]
pub struct PauseToggled {
    pub authority: Pubkey,
    pub paused: bool,
}

#[event]
pub struct PortalBridgedSol {
    pub owner_hash: [u8; 32],
    pub recovery_identifier: [u8; 32],
    pub portal: Pubkey,
    pub vault: Pubkey,
    pub operator: Pubkey,
    pub lamports: u64,
    pub created_at: i64,
    pub currency_mint: Pubkey,
    pub portal_bump: u8,
    pub vault_bump: u8,
    pub destination_chain_id: u64,
}

#[event]
pub struct PortalBridgedSpl {
    pub owner_hash: [u8; 32],
    pub recovery_identifier: [u8; 32],
    pub portal: Pubkey,
    pub vault: Pubkey,
    pub operator: Pubkey,
    pub vault_token_account: Pubkey,
    pub destination_token_account: Pubkey,
    pub mint: Pubkey,
    pub tokens: u64,
    pub created_at: i64,
    pub portal_bump: u8,
    pub vault_bump: u8,
    pub destination_chain_id: u64,
}

#[event]
pub struct PortalRecoveredSol {
    pub owner_hash: [u8; 32],
    pub recovery_identifier: [u8; 32],
    pub vault: Pubkey,
    pub recipient: Pubkey,
    pub lamports: u64,
    pub vault_bump: u8,
}

#[event]
pub struct PortalRecoveredSpl {
    pub owner_hash: [u8; 32],
    pub recovery_identifier: [u8; 32],
    pub vault: Pubkey,
    pub vault_token_account: Pubkey,
    pub recipient_token_account: Pubkey,
    pub recipient: Pubkey,
    pub mint: Pubkey,
    pub tokens: u64,
    pub vault_bump: u8,
}

#[event]
pub struct StealthSolVaultPrepared {
    pub owner_hash: [u8; 32],
    pub recovery_identifier: [u8; 32],
    pub vault: Pubkey,
}

#[event]
pub struct StealthSplAtaPrepared {
    pub owner_hash: [u8; 32],
    pub recovery_identifier: [u8; 32],
    pub vault: Pubkey,
    pub mint: Pubkey,
    pub vault_token_account: Pubkey,
}

