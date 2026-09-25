#![allow(ambiguous_glob_reexports)]

use anchor_lang::prelude::*;

use crate::error::PortalError;

pub mod initialize;
pub mod update_config;
pub mod pause;
pub mod create_stealth_sol;
pub mod create_stealth_spl_ata;
pub mod bridge_across_sol;
pub mod bridge_across_spl;
pub mod bridge_relay_sol;
pub mod bridge_relay_spl;
pub mod bridge_eco_spl;
pub mod recover_sol;
pub mod recover_spl;

pub use initialize::*;
pub use update_config::*;
pub use pause::*;
pub use create_stealth_sol::*;
pub use create_stealth_spl_ata::*;
pub use bridge_across_sol::*;
pub use bridge_across_spl::*;
pub use bridge_relay_sol::*;
pub use bridge_relay_spl::*;
pub use bridge_eco_spl::*;
pub use recover_sol::*;
pub use recover_spl::*;

/// Enforce that provider + LiFi fee transfers consume the full portal balance
/// and that the fee is no more than 1% in raw token units.
pub(crate) fn validate_lifi_amounts(
    input_amount: u64,
    provider_amount: u64,
    fee_amounts: &[u64],
) -> Result<u64> {
    require!(provider_amount > 0, PortalError::InsufficientFunds);

    let total_fee = fee_amounts.iter().try_fold(0u64, |total, fee| {
        total
            .checked_add(*fee)
            .ok_or(PortalError::LiFiAmountMismatch)
    })?;
    require!(
        provider_amount
            .checked_add(total_fee)
            .ok_or(PortalError::LiFiAmountMismatch)?
            == input_amount,
        PortalError::LiFiAmountMismatch
    );
    require!(total_fee <= input_amount / 100, PortalError::LiFiFeeTooHigh);

    Ok(total_fee)
}

#[cfg(test)]
mod tests {
    use super::validate_lifi_amounts;

    #[test]
    fn lifi_fee_limit_uses_exact_integer_percent_boundaries() {
        assert_eq!(validate_lifi_amounts(99, 99, &[]).unwrap(), 0);
        assert!(validate_lifi_amounts(99, 98, &[1]).is_err());
        assert_eq!(validate_lifi_amounts(100, 99, &[1]).unwrap(), 1);
    }

    #[test]
    fn lifi_amounts_must_consume_the_full_balance_without_overflow() {
        assert!(validate_lifi_amounts(1_000, 989, &[10]).is_err());
        assert!(validate_lifi_amounts(u64::MAX, u64::MAX, &[1]).is_err());
    }
}
