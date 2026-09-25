use anchor_lang::prelude::*;
use anchor_lang::solana_program::{
    instruction::{AccountMeta, Instruction},
    program::invoke,
};
use anchor_spl::token::{self, Approve, Mint, Revoke, Token, TokenAccount, TransferChecked};
use anchor_spl::{associated_token, token_2022};

use crate::error::PortalError;
use crate::events::PortalBridgedLifiSpl;
use crate::instructions::validate_lifi_amounts;
use crate::seeds::{CONFIG_SEED, PORTAL_META_SEED, PORTAL_SEED};
use crate::state::{PortalAccount, PortalConfig};

const ECO_PROGRAM_ID: Pubkey = pubkey!("EcooiHrTiMnfUBMw297gvPwX55HD8SCxA61tBBLV3yaV");
const ECO_FUND_DISCRIMINATOR: [u8; 8] = [218, 188, 111, 221, 152, 113, 174, 7];
const ECO_FUND_ACCOUNT_COUNT: usize = 10;
const ECO_FUND_DATA_LENGTH: usize = 173;
const ECO_DESTINATION_OFFSET: usize = 8;
const ECO_CREATOR_OFFSET: usize = 56;
const ECO_NATIVE_AMOUNT_OFFSET: usize = 120;
const ECO_TOKEN_COUNT_OFFSET: usize = 128;
const ECO_TOKEN_MINT_OFFSET: usize = 132;
const ECO_TOKEN_AMOUNT_OFFSET: usize = 164;
const ECO_ALLOW_PARTIAL_OFFSET: usize = 172;

pub fn handler<'info>(
    ctx: Context<'_, '_, '_, 'info, BridgeEcoSpl<'info>>,
    owner_hash: [u8; 32],
    recovery_identifier: [u8; 32],
    input_amount: u64,
    provider_amount: u64,
    fee_amounts: Vec<u64>,
    provider_instruction_data: Vec<u8>,
) -> Result<()> {
    require_keys_eq!(
        ctx.accounts.provider_program.key(),
        ECO_PROGRAM_ID,
        PortalError::UnsupportedLiFiProvider
    );

    let token_balance = ctx.accounts.vault_token_account.amount;
    require!(
        input_amount == token_balance,
        PortalError::InsufficientFunds
    );
    let expected_remaining_accounts = fee_amounts
        .len()
        .checked_add(ECO_FUND_ACCOUNT_COUNT)
        .ok_or(PortalError::InvalidLiFiProviderInstruction)?;
    require!(
        ctx.remaining_accounts.len() == expected_remaining_accounts,
        PortalError::InvalidLiFiProviderInstruction
    );
    let total_fee = validate_lifi_amounts(input_amount, provider_amount, &fee_amounts)?;

    let owner_hash_ref = owner_hash.as_ref();
    let recovery_id_ref = recovery_identifier.as_ref();
    let vault_bump = ctx.bumps.vault;
    let vault_bump_seed = [vault_bump];
    let vault_seeds: &[&[u8]] = &[
        PORTAL_SEED,
        owner_hash_ref,
        recovery_id_ref,
        &vault_bump_seed,
    ];
    let signer_seeds = [vault_seeds];

    let (fee_recipients, provider_accounts) = ctx.remaining_accounts.split_at(fee_amounts.len());
    validate_eco_fund_instruction(
        provider_accounts,
        &provider_instruction_data,
        ctx.accounts.config.destination_chain_id,
        ctx.accounts.operator.key(),
        ctx.accounts.vault_token_account.key(),
        ctx.accounts.mint.key(),
        provider_amount,
    )?;

    for (fee_recipient, fee_amount) in fee_recipients.iter().zip(fee_amounts) {
        if fee_amount == 0 {
            continue;
        }
        token::transfer_checked(
            CpiContext::new_with_signer(
                ctx.accounts.token_program.to_account_info(),
                TransferChecked {
                    from: ctx.accounts.vault_token_account.to_account_info(),
                    mint: ctx.accounts.mint.to_account_info(),
                    to: fee_recipient.to_account_info(),
                    authority: ctx.accounts.vault.to_account_info(),
                },
                &signer_seeds,
            ),
            fee_amount,
            ctx.accounts.mint.decimals,
        )?;
    }

    // Eco's LiFi transaction expects the on-curve quote address to authorize
    // the token transfer. Give that operator an exact, transaction-scoped
    // delegation over the PDA ATA, invoke the quoted Eco instruction, then
    // revoke the delegation before returning.
    token::approve(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            Approve {
                to: ctx.accounts.vault_token_account.to_account_info(),
                delegate: ctx.accounts.operator.to_account_info(),
                authority: ctx.accounts.vault.to_account_info(),
            },
            &signer_seeds,
        ),
        provider_amount,
    )?;

    let account_metas = provider_accounts
        .iter()
        .map(|account| {
            if account.is_writable {
                AccountMeta::new(*account.key, account.is_signer)
            } else {
                AccountMeta::new_readonly(*account.key, account.is_signer)
            }
        })
        .collect();
    let provider_instruction = Instruction {
        program_id: ctx.accounts.provider_program.key(),
        accounts: account_metas,
        data: provider_instruction_data,
    };
    let mut invoke_accounts = provider_accounts.to_vec();
    invoke_accounts.push(ctx.accounts.provider_program.to_account_info());
    invoke(&provider_instruction, &invoke_accounts)?;

    token::revoke(CpiContext::new_with_signer(
        ctx.accounts.token_program.to_account_info(),
        Revoke {
            source: ctx.accounts.vault_token_account.to_account_info(),
            authority: ctx.accounts.vault.to_account_info(),
        },
        &signer_seeds,
    ))?;

    ctx.accounts.vault_token_account.reload()?;
    require!(
        ctx.accounts.vault_token_account.amount == 0,
        PortalError::LiFiProviderAmountMismatch
    );

    let portal = &mut ctx.accounts.portal;
    let clock = Clock::get()?;
    portal.owner_hash = owner_hash;
    portal.recovery_identifier = recovery_identifier;
    portal.is_used = true;
    portal.created_at = clock.unix_timestamp;
    portal.amount_withdrawn = input_amount;
    portal.currency_mint = ctx.accounts.mint.key();
    portal.bump = ctx.bumps.portal;
    portal.vault_bump = vault_bump;

    emit!(PortalBridgedLifiSpl {
        owner_hash,
        recovery_identifier,
        portal: portal.key(),
        vault: ctx.accounts.vault.key(),
        operator: ctx.accounts.operator.key(),
        vault_token_account: ctx.accounts.vault_token_account.key(),
        provider_program: ctx.accounts.provider_program.key(),
        mint: ctx.accounts.mint.key(),
        tokens: input_amount,
        provider_tokens: provider_amount,
        fee_tokens: total_fee,
        created_at: portal.created_at,
        portal_bump: portal.bump,
        vault_bump: portal.vault_bump,
        destination_chain_id: ctx.accounts.config.destination_chain_id,
    });

    Ok(())
}

fn validate_eco_fund_instruction(
    accounts: &[AccountInfo<'_>],
    data: &[u8],
    destination_chain_id: u64,
    operator: Pubkey,
    vault_token_account: Pubkey,
    mint: Pubkey,
    provider_amount: u64,
) -> Result<()> {
    require!(
        accounts.len() == ECO_FUND_ACCOUNT_COUNT,
        PortalError::InvalidLiFiProviderInstruction
    );
    require_keys_eq!(
        *accounts[0].key,
        operator,
        PortalError::InvalidLiFiProviderInstruction
    );
    require_keys_eq!(
        *accounts[1].key,
        operator,
        PortalError::InvalidLiFiProviderInstruction
    );
    require!(
        accounts[0].is_signer && accounts[1].is_signer,
        PortalError::InvalidLiFiProviderInstruction
    );
    require_keys_eq!(
        *accounts[3].key,
        anchor_spl::token::ID,
        PortalError::InvalidLiFiProviderInstruction
    );
    require_keys_eq!(
        *accounts[4].key,
        token_2022::ID,
        PortalError::InvalidLiFiProviderInstruction
    );
    require_keys_eq!(
        *accounts[5].key,
        associated_token::ID,
        PortalError::InvalidLiFiProviderInstruction
    );
    require_keys_eq!(
        *accounts[6].key,
        anchor_lang::system_program::ID,
        PortalError::InvalidLiFiProviderInstruction
    );
    require_keys_eq!(
        *accounts[7].key,
        vault_token_account,
        PortalError::InvalidLiFiProviderInstruction
    );
    require_keys_eq!(
        *accounts[9].key,
        mint,
        PortalError::InvalidLiFiProviderInstruction
    );
    require!(
        accounts[2].is_writable && accounts[7].is_writable && accounts[8].is_writable,
        PortalError::InvalidLiFiProviderInstruction
    );

    validate_eco_fund_data(data, destination_chain_id, operator, mint, provider_amount)
}

fn validate_eco_fund_data(
    data: &[u8],
    destination_chain_id: u64,
    operator: Pubkey,
    mint: Pubkey,
    provider_amount: u64,
) -> Result<()> {
    require!(
        data.len() == ECO_FUND_DATA_LENGTH && data[..8] == ECO_FUND_DISCRIMINATOR,
        PortalError::InvalidLiFiProviderInstruction
    );

    let destination = read_u64(data, ECO_DESTINATION_OFFSET);
    require!(
        destination == destination_chain_id,
        PortalError::LiFiDestinationMismatch
    );

    let creator = Pubkey::new_from_array(read_array_32(data, ECO_CREATOR_OFFSET));
    require_keys_eq!(creator, operator, PortalError::LiFiRefundRecipientMismatch);
    require!(
        read_u64(data, ECO_NATIVE_AMOUNT_OFFSET) == 0
            && read_u32(data, ECO_TOKEN_COUNT_OFFSET) == 1,
        PortalError::InvalidLiFiProviderInstruction
    );
    require_keys_eq!(
        Pubkey::new_from_array(read_array_32(data, ECO_TOKEN_MINT_OFFSET)),
        mint,
        PortalError::InvalidLiFiProviderInstruction
    );
    require!(
        read_u64(data, ECO_TOKEN_AMOUNT_OFFSET) == provider_amount
            && data[ECO_ALLOW_PARTIAL_OFFSET] == 0,
        PortalError::LiFiProviderAmountMismatch
    );

    Ok(())
}

fn read_u32(data: &[u8], offset: usize) -> u32 {
    let mut bytes = [0u8; 4];
    bytes.copy_from_slice(&data[offset..offset + 4]);
    u32::from_le_bytes(bytes)
}

fn read_u64(data: &[u8], offset: usize) -> u64 {
    let mut bytes = [0u8; 8];
    bytes.copy_from_slice(&data[offset..offset + 8]);
    u64::from_le_bytes(bytes)
}

fn read_array_32(data: &[u8], offset: usize) -> [u8; 32] {
    let mut bytes = [0u8; 32];
    bytes.copy_from_slice(&data[offset..offset + 32]);
    bytes
}

#[cfg(test)]
mod tests {
    use super::*;

    fn valid_eco_fund_data(
        destination_chain_id: u64,
        operator: Pubkey,
        mint: Pubkey,
        provider_amount: u64,
    ) -> Vec<u8> {
        let mut data = vec![0u8; ECO_FUND_DATA_LENGTH];
        data[..8].copy_from_slice(&ECO_FUND_DISCRIMINATOR);
        data[ECO_DESTINATION_OFFSET..ECO_DESTINATION_OFFSET + 8]
            .copy_from_slice(&destination_chain_id.to_le_bytes());
        data[ECO_CREATOR_OFFSET..ECO_CREATOR_OFFSET + 32].copy_from_slice(operator.as_ref());
        data[ECO_TOKEN_COUNT_OFFSET..ECO_TOKEN_COUNT_OFFSET + 4]
            .copy_from_slice(&1u32.to_le_bytes());
        data[ECO_TOKEN_MINT_OFFSET..ECO_TOKEN_MINT_OFFSET + 32].copy_from_slice(mint.as_ref());
        data[ECO_TOKEN_AMOUNT_OFFSET..ECO_TOKEN_AMOUNT_OFFSET + 8]
            .copy_from_slice(&provider_amount.to_le_bytes());
        data
    }

    #[test]
    fn accepts_the_supported_one_token_eco_fund_layout() {
        let operator = Pubkey::new_unique();
        let mint = Pubkey::new_unique();
        let data = valid_eco_fund_data(42_161, operator, mint, 997_500);

        assert!(validate_eco_fund_data(&data, 42_161, operator, mint, 997_500).is_ok());
    }

    #[test]
    fn rejects_eco_abi_drift_and_partial_funding() {
        let operator = Pubkey::new_unique();
        let mint = Pubkey::new_unique();
        let mut data = valid_eco_fund_data(42_161, operator, mint, 997_500);

        data[ECO_ALLOW_PARTIAL_OFFSET] = 1;
        assert!(validate_eco_fund_data(&data, 42_161, operator, mint, 997_500).is_err());

        data[ECO_ALLOW_PARTIAL_OFFSET] = 0;
        data.push(0);
        assert!(validate_eco_fund_data(&data, 42_161, operator, mint, 997_500).is_err());
    }
}

#[derive(Accounts)]
#[instruction(
    owner_hash: [u8; 32],
    recovery_identifier: [u8; 32],
    input_amount: u64,
    provider_amount: u64,
    fee_amounts: Vec<u64>,
    provider_instruction_data: Vec<u8>
)]
pub struct BridgeEcoSpl<'info> {
    #[account(
        mut,
        constraint = operator.key() == config.operator @ PortalError::UnauthorizedOperator,
    )]
    pub operator: Signer<'info>,

    #[account(
        seeds = [CONFIG_SEED],
        bump = config.bump,
        constraint = !config.paused @ PortalError::Paused,
    )]
    pub config: Account<'info, PortalConfig>,

    #[account(
        init,
        payer = operator,
        space = 8 + PortalAccount::INIT_SPACE,
        seeds = [PORTAL_META_SEED, owner_hash.as_ref(), recovery_identifier.as_ref()],
        bump,
    )]
    pub portal: Account<'info, PortalAccount>,

    /// CHECK: Portal vault PDA; signs fee transfers and exact token delegation.
    #[account(
        mut,
        seeds = [PORTAL_SEED, owner_hash.as_ref(), recovery_identifier.as_ref()],
        bump,
        constraint = owner_hash != [0u8; 32] @ PortalError::InvalidOwnerHash,
    )]
    pub vault: UncheckedAccount<'info>,

    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = vault,
        constraint = vault_token_account.amount > 0 @ PortalError::EmptyVaultTokenAccount,
    )]
    pub vault_token_account: Account<'info, TokenAccount>,

    pub mint: Account<'info, Mint>,

    /// CHECK: Restricted to Eco's verified mainnet program in the handler.
    #[account(executable)]
    pub provider_program: UncheckedAccount<'info>,

    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}
