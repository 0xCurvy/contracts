// `sol!`-expanded code is not ours to lint; everything hand-written in this file is
// still checked by the crate's normal lint level.
#![allow(clippy::all)]
//! Contract bindings, expanded by `alloy::sol!` from the vendored HARDHAT artifacts in
//! `src/artifacts/` (written by `../../extract-artifacts.mjs`).
//!
//! Those artifacts are the SAME ones the validated Hardhat/Ignition deploy pipeline
//! produces, so the bytecode bound here is bit-for-bit what the pipeline deploys.
//!
//! Each contract gets its own module: `sol!` re-emits shared struct namespaces (e.g.
//! `CurvyTypes`) on every invocation, so two contracts sharing one would collide inside
//! a single module. These module names are a stable public API — downstream code
//! imports `curvy_bindings::curvy_aggregator_alpha_v2::CurvyAggregatorAlphaV2::…`.
//!
//! `sol!` resolves file paths relative to `CARGO_MANIFEST_DIR`.

/// Binds one contract into its own module. Trailing idents are forwarded into
/// `#[sol(rpc, …)]`.
///
/// `ignore_unlinked` is opt-in rather than blanket-applied on purpose: a contract that
/// newly acquires a library link then fails to compile here — loudly — instead of
/// silently losing its `BYTECODE` constant and failing at deploy time.
macro_rules! bind {
    ($module:ident, $contract:ident $(, $flag:ident)*) => {
        pub mod $module {
            alloy::sol!(
                #[allow(missing_docs)]
                #[sol(rpc $(, $flag)*)]
                $contract,
                concat!("src/artifacts/", stringify!($contract), ".json")
            );
        }
    };
}

bind!(curvy_vault_v2, CurvyVaultV2);
// Links the PoseidonT4 library, so its creation bytecode still carries solc's `__$…$__`
// placeholder. `constants::CURVY_AGGREGATOR_ALPHA_V2_UNLINKED_BYTECODE` carries the
// unlinked code; `deploy_for_testing` substitutes the library address.
bind!(
    curvy_aggregator_alpha_v2,
    CurvyAggregatorAlphaV2,
    ignore_unlinked
);
bind!(portal_factory, PortalFactory);
bind!(portal, Portal);
bind!(curvy_aggregation_verifier, CurvyAggregationVerifier);
bind!(
    curvy_pending_notes_commitment_verifier,
    CurvyPendingNotesCommitmentVerifier
);
bind!(curvy_withdrawal_verifier, CurvyWithdrawalVerifier);
bind!(poseidon_t4, PoseidonT4);
bind!(erc1967_proxy, ERC1967Proxy);
bind!(erc20_mock, ERC20Mock);
bind!(multicall3, Multicall3);
