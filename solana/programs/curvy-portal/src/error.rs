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

    #[msg("Invalid destination: operator address mismatch")]
    InvalidDestination,

    #[msg("Vault token account has no balance")]
    EmptyVaultTokenAccount,

    #[msg("Invalid secp256k1 signature or public key mismatch")]
    InvalidSecp256k1Signature,

    #[msg("Recovery message hash must be 32 bytes")]
    InvalidMessageHash,
}
