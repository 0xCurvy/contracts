use anchor_lang::prelude::*;
use anchor_spl::associated_token::get_associated_token_address_with_program_id;

#[derive(AnchorSerialize, AnchorDeserialize, Clone, PartialEq, Eq)]
pub struct AcrossBridgeQuoteParams {
    pub recipient: Pubkey,
    pub output_token: Pubkey,
    pub output_amount: [u8; 32],
    pub destination_chain_id: u64,
    pub exclusive_relayer: Pubkey,
    pub quote_timestamp: u32,
    pub fill_deadline: u32,
    pub exclusivity_parameter: u32,
    pub message: Vec<u8>,
}

pub fn output_amount_bytes32(amount: u64) -> [u8; 32] {
    let mut o = [0u8; 32];
    o[24..32].copy_from_slice(&amount.to_be_bytes());
    o
}

pub fn evm_address_to_pubkey(address20: [u8; 20]) -> Pubkey {
    let mut a = [0u8; 32];
    a[12..32].copy_from_slice(&address20);
    Pubkey::new_from_array(a)
}

pub fn expected_state_pda(state_seed: u64) -> (Pubkey, u8) {
    Pubkey::find_program_address(
        &[b"state", &state_seed.to_le_bytes()],
        &crate::across::ID,
    )
}

pub fn expected_event_authority_pda() -> (Pubkey, u8) {
    Pubkey::find_program_address(&[b"__event_authority"], &crate::across::ID)
}

pub fn expected_spoke_vault(state: &Pubkey, mint: &Pubkey, token_program: &Pubkey) -> Pubkey {
    get_associated_token_address_with_program_id(state, mint, token_program)
}

pub fn validate_across_accounts(
    across_state: &AccountInfo,
    across_vault: &AccountInfo,
    across_event_authority: &AccountInfo,
    mint: &Pubkey,
    token_program: &Pubkey,
    state_seed: u64,
) -> Result<()> {
    let (expected_state, _) = expected_state_pda(state_seed);
    require_keys_eq!(expected_state, across_state.key());

    let (expected_ev, _) = expected_event_authority_pda();
    require_keys_eq!(expected_ev, across_event_authority.key());

    let expected_vault = expected_spoke_vault(&across_state.key(), mint, token_program);
    require_keys_eq!(expected_vault, across_vault.key());
    Ok(())
}
