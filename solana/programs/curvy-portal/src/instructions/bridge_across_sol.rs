use anchor_lang::prelude::*;
use anchor_lang::system_program;
use anchor_spl::associated_token::AssociatedToken;
use anchor_spl::token::spl_token::native_mint;
use anchor_spl::token::{self, approve, Approve, Mint, SyncNative, Token, TokenAccount};

use crate::across::cpi::{accounts::Deposit, deposit};
use crate::across_bridge::{validate_across_accounts, AcrossBridgeQuoteParams};
use crate::error::PortalError;
use crate::events::PortalBridgedSol;
use crate::seeds::{CONFIG_SEED, PORTAL_META_SEED, PORTAL_SEED};
use crate::state::{PortalAccount, PortalConfig};

pub fn handler(
    ctx: Context<BridgeSol>,
    owner_hash: [u8; 32],
    recovery_identifier: [u8; 32],
    input_amount: u64,
    across_state_seed: u64,
    quote: AcrossBridgeQuoteParams,
) -> Result<()> {
    require!(quote.message.len() <= 512, PortalError::AcrossMessageTooLong);
    require!(input_amount > 0, PortalError::InsufficientFunds);

    let rent = Rent::get()?;
    let min_vault_rent = rent.minimum_balance(0);
    let vault_lamports = ctx.accounts.vault.lamports();
    require!(
        vault_lamports >= min_vault_rent
            .checked_add(input_amount)
            .ok_or(PortalError::InsufficientFunds)?,
        PortalError::AcrossInsufficientSolForWrap
    );

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
    system_program::transfer(
        CpiContext::new_with_signer(
            ctx.accounts.system_program.to_account_info(),
            system_program::Transfer {
                from: ctx.accounts.vault.to_account_info(),
                to: ctx.accounts.vault_wsol_ata.to_account_info(),
            },
            &signer_seeds,
        ),
        input_amount,
    )?;

    token::sync_native(CpiContext::new_with_signer(
        ctx.accounts.token_program.to_account_info(),
        SyncNative {
            account: ctx.accounts.vault_wsol_ata.to_account_info(),
        },
        &signer_seeds,
    ))?;

    ctx.accounts.vault_wsol_ata.reload()?;
    require_eq!(
        ctx.accounts.vault_wsol_ata.amount,
        input_amount,
        PortalError::AcrossInputAmountMismatch
    );

    // Across SVM deposit transfers from `depositor_token_account` using `delegate` authority.
    // Therefore we must approve `across_delegate` as delegate on the WSOL vault ATA.
    approve(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            Approve {
                to: ctx.accounts.vault_wsol_ata.to_account_info(),
                delegate: ctx.accounts.across_delegate.to_account_info(),
                authority: ctx.accounts.vault.to_account_info(),
            },
            &signer_seeds,
        ),
        input_amount,
    )?;

    validate_across_accounts(
        &ctx.accounts.across_state,
        &ctx.accounts.across_vault,
        &ctx.accounts.across_event_authority,
        &native_mint::ID,
        &ctx.accounts.token_program.key(),
        across_state_seed,
    )?;

    let cpi_accounts = Deposit {
        signer: ctx.accounts.vault.to_account_info(),
        state: ctx.accounts.across_state.to_account_info(),
        delegate: ctx.accounts.across_delegate.to_account_info(),
        depositor_token_account: ctx.accounts.vault_wsol_ata.to_account_info(),
        vault: ctx.accounts.across_vault.to_account_info(),
        mint: ctx.accounts.wsol_mint.to_account_info(),
        token_program: ctx.accounts.token_program.to_account_info(),
        associated_token_program: ctx.accounts.associated_token_program.to_account_info(),
        system_program: ctx.accounts.system_program.to_account_info(),
        event_authority: ctx.accounts.across_event_authority.to_account_info(),
        program: ctx.accounts.across_program.to_account_info(),
    };

    let cpi_ctx = CpiContext::new_with_signer(
        ctx.accounts.across_program.to_account_info(),
        cpi_accounts,
        &signer_seeds,
    );

    deposit(
        cpi_ctx,
        ctx.accounts.vault.key(),
        quote.recipient,
        native_mint::ID,
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
    portal.currency_mint = native_mint::ID;
    portal.bump = ctx.bumps.portal;
    portal.vault_bump = vault_bump;

    emit!(PortalBridgedSol {
        owner_hash: owner_hash,
        recovery_identifier: recovery_identifier,
        portal: portal.key(),
        lamports: input_amount,
        vault: ctx.accounts.vault.key(),
        operator: ctx.accounts.operator.key(),
        created_at: portal.created_at,
        currency_mint: portal.currency_mint,
        portal_bump: portal.bump,
        vault_bump: portal.vault_bump,
        destination_chain_id: quote.destination_chain_id,
    });

    Ok(())
}

#[derive(Accounts)]
#[instruction(owner_hash: [u8; 32], recovery_identifier: [u8; 32], input_amount: u64, across_state_seed: u64, quote: AcrossBridgeQuoteParams)]
pub struct BridgeSol<'info> {
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

    /// CHECK: Vault PDA — signer for wrap + Across CPI.
    #[account(
        mut,
        seeds = [PORTAL_SEED, owner_hash.as_ref(), recovery_identifier.as_ref()],
        bump,
        constraint = owner_hash != [0u8; 32] @ PortalError::InvalidOwnerHash,
        constraint = vault.lamports() > 0 @ PortalError::InsufficientFunds,
    )]
    pub vault: UncheckedAccount<'info>,

    #[account(
        init_if_needed,
        payer = operator,
        associated_token::mint = wsol_mint,
        associated_token::authority = vault,
    )]
    pub vault_wsol_ata: Account<'info, TokenAccount>,

    #[account(
        constraint = wsol_mint.key() == native_mint::ID @ PortalError::InvalidNativeMint,
    )]
    pub wsol_mint: Account<'info, Mint>,

    /// CHECK: Across Spoke program (IDL: `declare_program!(across)`).
    #[account(address = crate::across::ID_CONST)]
    pub across_program: AccountInfo<'info>,

    /// CHECK: Spoke `State` PDA.
    #[account(mut)]
    pub across_state: AccountInfo<'info>,

    /// CHECK: Delegate account from quote.
    pub across_delegate: AccountInfo<'info>,

    /// CHECK: Spoke vault ATA for WSOL.
    #[account(mut)]
    pub across_vault: AccountInfo<'info>,

    /// CHECK: Anchor event authority PDA.
    pub across_event_authority: AccountInfo<'info>,

    pub token_program: Program<'info, Token>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}
