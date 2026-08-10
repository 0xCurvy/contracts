use anchor_lang::prelude::*;
use solana_program::hash::hashv;
use solana_program::secp256k1_recover::secp256k1_recover;
use libsecp256k1::PublicKey as LibSecpPublicKey;

use crate::error::PortalError;
use crate::seeds::SOLANA_RECOVERY_DOMAIN;


pub fn recovery_identifier_from_secp_pubkey_xy(pubkey_xy: &[u8; 64]) -> Result<[u8; 32]> {
    let mut uncompressed = [0u8; 65];
    uncompressed[0] = 0x04;
    uncompressed[1..].copy_from_slice(pubkey_xy);
    let pk = LibSecpPublicKey::parse_slice(&uncompressed, None)
        .map_err(|_| error!(PortalError::InvalidSecp256k1Signature))?;
    let compressed = pk.serialize_compressed();
    let h = hashv(&[SOLANA_RECOVERY_DOMAIN, compressed.as_ref()]);
    Ok(h.to_bytes())
}

pub fn verify_sol_recovery(
    program_id: &Pubkey,
    owner_hash: &[u8; 32],
    recovery_identifier: &[u8; 32],
    recipient: &Pubkey,
    signature: &[u8; 64],
    recovery_id: u8,
) -> Result<()> {
    let digest = hashv(&[
        SOLANA_RECOVERY_DOMAIN,
        program_id.as_ref(),
        owner_hash.as_ref(),
        recovery_identifier.as_ref(),
        recipient.as_ref(),
        b"SOL",
    ])
    .to_bytes();

    let recovered = secp256k1_recover(&digest, recovery_id, signature)
        .map_err(|_| error!(PortalError::InvalidSecp256k1Signature))?;
    let derived = recovery_identifier_from_secp_pubkey_xy(&recovered.to_bytes())?;
    require!(
        derived == *recovery_identifier,
        PortalError::InvalidSecp256k1Signature
    );
    Ok(())
}

pub fn verify_spl_recovery(
    program_id: &Pubkey,
    owner_hash: &[u8; 32],
    recovery_identifier: &[u8; 32],
    recipient: &Pubkey,
    mint: &Pubkey,
    signature: &[u8; 64],
    recovery_id: u8,
) -> Result<()> {
    let digest = hashv(&[
        SOLANA_RECOVERY_DOMAIN,
        program_id.as_ref(),
        owner_hash.as_ref(),
        recovery_identifier.as_ref(),
        recipient.as_ref(),
        mint.as_ref(),
        b"SPL",
    ])
    .to_bytes();

    let recovered = secp256k1_recover(&digest, recovery_id, signature)
        .map_err(|_| error!(PortalError::InvalidSecp256k1Signature))?;
    let derived = recovery_identifier_from_secp_pubkey_xy(&recovered.to_bytes())?;
    require!(
        derived == *recovery_identifier,
        PortalError::InvalidSecp256k1Signature
    );
    Ok(())
}
