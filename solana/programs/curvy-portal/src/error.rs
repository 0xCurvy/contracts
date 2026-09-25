use anchor_lang::prelude::*;

#[error_code]
pub enum PortalError {
    #[msg("Unauthorized: caller is not the operator")]
    UnauthorizedOperator,

    #[msg("Unauthorized: caller is not the authority")]
    UnauthorizedAuthority,

    #[msg("Unauthorized: caller is not the recovery signer")]
    UnauthorizedRecovery,

    #[msg("Vault has insufficient funds for bridging")]
    InsufficientFunds,

    #[msg("Portal has already been used")]
    AlreadyUsed,

    #[msg("Invalid owner hash: must be non-zero")]
    InvalidOwnerHash,

    #[msg("SOL vault must be system-owned; use a new (owner_hash, recovery) or reset local state")]
    InvalidVaultOwner,

    #[msg("Invalid destination: operator address mismatch")]
    InvalidDestination,

    #[msg("Vault token account has no balance")]
    EmptyVaultTokenAccount,

    #[msg("Contract is paused")]
    Paused,

    #[msg("Portal authority is immutable")]
    AuthorityImmutable,

    #[msg("Invalid secp256k1 signature or public key mismatch")]
    InvalidSecp256k1Signature,

    #[msg("Recovery message hash must be 32 bytes")]
    InvalidMessageHash,

    #[msg("Across bridge: input amount must match vault token balance")]
    AcrossInputAmountMismatch,

    #[msg("Across bridge: message payload too large")]
    AcrossMessageTooLong,

    #[msg("Across bridge: SOL vault cannot cover wrap amount plus rent")]
    AcrossInsufficientSolForWrap,

    #[msg("Across bridge: mint must be wrapped SOL (native mint)")]
    InvalidNativeMint,

    #[msg("LiFi quote amounts do not consume the full portal balance")]
    LiFiAmountMismatch,

    #[msg("LiFi fee exceeds the portal safety limit")]
    LiFiFeeTooHigh,

    #[msg("LiFi fee recipient count does not match the quoted fee amounts")]
    LiFiFeeRecipientMismatch,

    #[msg("Unsupported LiFi bridge provider")]
    UnsupportedLiFiProvider,

    #[msg("LiFi provider did not consume the quoted portal token amount")]
    LiFiProviderAmountMismatch,

    #[msg("LiFi provider instruction does not match the approved adapter layout")]
    InvalidLiFiProviderInstruction,

    #[msg("LiFi provider destination does not match the portal destination chain")]
    LiFiDestinationMismatch,

    #[msg("LiFi provider refund recipient does not match the operator")]
    LiFiRefundRecipientMismatch,
}
