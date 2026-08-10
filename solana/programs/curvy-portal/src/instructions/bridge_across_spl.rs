use anchor_lang::prelude::*;
use anchor_spl::associated_token::AssociatedToken;
use anchor_spl::token::{approve, Approve, Mint, Token, TokenAccount};

use crate::across::cpi::{accounts::Deposit, deposit};
use crate::across_bridge::{validate_across_accounts, AcrossBridgeQuoteParams};
use crate::error::PortalError;
use crate::events::PortalBridgedSpl;
use crate::seeds::{CONFIG_SEED, PORTAL_META_SEED, PORTAL_SEED};
use crate::state::{PortalAccount, PortalConfig};

pub fn handler(
    ctx: Context<BridgeSpl>,
    owner_hash: [u8; 32],
    recovery_identifier: [u8; 32],
    input_amount: u64,
    across_state_seed: u64,
    quote: AcrossBridgeQuoteParams,
) -> Result<()> {
    require!(quote.message.len() <= 512, PortalError::AcrossMessageTooLong);
    require!(input_amount > 0, PortalError::InsufficientFunds);

    let token_balance = ctx.accounts.vault_token_account.amount;
    require!(
        input_amount == token_balance,
        PortalError::AcrossInputAmountMismatch
    );

    validate_across_accounts(
        &ctx.accounts.across_state,
        &ctx.accounts.across_vault,
        &ctx.accounts.across_event_authority,
        &ctx.accounts.mint.key(),
        &ctx.accounts.token_program.key(),
        across_state_seed,
    )?;

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

    let cpi_accounts = Deposit {
        signer: ctx.accounts.vault.to_account_info(),
        state: ctx.accounts.across_state.to_account_info(),
        delegate: ctx.accounts.across_delegate.to_account_info(),
        depositor_token_account: ctx.accounts.vault_token_account.to_account_info(),
        vault: ctx.accounts.across_vault.to_account_info(),
        mint: ctx.accounts.mint.to_account_info(),
        token_program: ctx.accounts.token_program.to_account_info(),
        associated_token_program: ctx.accounts.associated_token_program.to_account_info(),
        system_program: ctx.accounts.system_program.to_account_info(),
        event_authority: ctx.accounts.across_event_authority.to_account_info(),
        program: ctx.accounts.across_program.to_account_info(),
    };

    let signer_seeds = [vault_seeds];
    let cpi_ctx = CpiContext::new_with_signer(
        ctx.accounts.across_program.to_account_info(),
        cpi_accounts,
        &signer_seeds,
    );

    // Across SVM deposit transfers from `depositor_token_account` using `delegate` authority.
    // That requires the depositor token account's delegate to be set to `across_delegate`
    // with allowance >= `input_amount`.
    approve(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            Approve {
                to: ctx.accounts.vault_token_account.to_account_info(),
                delegate: ctx.accounts.across_delegate.to_account_info(),
                authority: ctx.accounts.vault.to_account_info(),
            },
            &signer_seeds,
        ),
        input_amount,
    )?;

    deposit(
        cpi_ctx,
        ctx.accounts.vault.key(),
        quote.recipient,
        ctx.accounts.mint.key(),
        quote.output_token,
        input_amount,
        quote.output_amount,
        quote.destination_chain_id,
        quote.exclusive_relayer,
        quote.quote_timestamp,
        quote.fill_deadline,
        quote.exclusivity_parameter,
        quote.message.clone(),
    )?;

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

    emit!(PortalBridgedSpl {
        owner_hash: owner_hash,
        recovery_identifier: recovery_identifier,
        portal: portal.key(),
        tokens: input_amount,
        vault: ctx.accounts.vault.key(),
        operator: ctx.accounts.operator.key(),
        vault_token_account: ctx.accounts.vault_token_account.key(),
        destination_token_account: ctx.accounts.across_vault.key(),
        mint: ctx.accounts.mint.key(),
        created_at: portal.created_at,
        portal_bump: portal.bump,
        vault_bump: portal.vault_bump,
        destination_chain_id: quote.destination_chain_id,
    });

    Ok(())
}

#[derive(Accounts)]
#[instruction(owner_hash: [u8; 32], recovery_identifier: [u8; 32], input_amount: u64, across_state_seed: u64, quote: AcrossBridgeQuoteParams)]
pub struct BridgeSpl<'info> {
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

    /// CHECK: Vault PDA — signer for Across CPI.
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

    /// CHECK: Across Spoke program (IDL: `declare_program!(across)`).
    #[account(address = crate::across::ID_CONST)]
    pub across_program: AccountInfo<'info>,

    /// CHECK: Spoke `State` PDA (`["state", seed]`).
    #[account(mut)]
    pub across_state: AccountInfo<'info>,

    /// CHECK: Delegate account required by Spoke (from quote / simulation).
    pub across_delegate: AccountInfo<'info>,

    /// CHECK: Spoke vault ATA for `mint`.
    #[account(mut)]
    pub across_vault: AccountInfo<'info>,

    /// CHECK: Anchor event authority PDA.
    pub across_event_authority: AccountInfo<'info>,

    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}
