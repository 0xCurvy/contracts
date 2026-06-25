pub const CONFIG_SEED: &[u8] = b"config";
pub const PORTAL_SEED: &[u8] = b"portal";
pub const PORTAL_META_SEED: &[u8] = b"portal_meta";

/// Arbitrum chain ID — the destination for all entry bridge portals
pub const ARBITRUM_CHAIN_ID: u64 = 42161;

/// Domain tag for Solana recovery pubkey derivation.
/// recovery_pubkey = SHA-256(SOLANA_RECOVERY_DOMAIN || compressed_secp256k1_pubkey)
/// Must match the constant in packages/sdk/src/utils/address.ts
pub const SOLANA_RECOVERY_DOMAIN: &[u8] = b"curvy-solana-recovery-v1";
