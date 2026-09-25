//! Compile-time guard on the public API surface downstream consumers import.
//!
//! blokli (`chain/indexer`, `chain/rpc`, `bloklid`, `api/tests`) pins this crate from
//! crates.io, so a rename or a moved module here is a breaking change that would only
//! surface in a different repository. Every path below is one blokli actually imports —
//! if this file stops compiling, the consumer stops compiling.
//!
//! Not shipped: `Cargo.toml`'s `include` list covers `src/**`, so `tests/` never reaches
//! the published crate.
#![allow(unused_imports)]

// chain/indexer/src/handlers/curvy.rs + chain/indexer/src/constants.rs
use curvy_bindings::curvy_aggregator_alpha_v2::CurvyAggregatorAlphaV2::{
    CommittedNotes, CommittedNullifiers, CurvyAggregatorAlphaV2Events, PendingNotes,
};
// chain/rpc/src/rpc.rs
use curvy_bindings::{
    curvy_aggregator_alpha_v2::CurvyAggregatorAlphaV2, curvy_vault_v2::CurvyVaultV2,
    portal_factory::PortalFactory,
};
// bloklid/src/bin/blokli-contract-deployer.rs
use curvy_bindings::{CurvyContractAddresses, config::CurvyContractInstances};
// api/tests/curvy_event_pipeline_test.rs
use curvy_bindings::{constants::DEV_PORTAL_DEPLOYMENT_FEE, portal_factory::CurvyTypes::Note};
// Consumers reach alloy through this crate so their types unify with ours.
use curvy_bindings::exports::alloy::{
    primitives::{Address, B256, U256},
    sol_types::SolEvent,
};

#[test]
fn event_types_decode_and_keep_their_signatures() {
    // The indexer matches on these signatures; a silent ABI change would break
    // historical log decoding rather than fail loudly.
    assert_eq!(
        PendingNotes::SIGNATURE,
        "PendingNotes(uint256[],uint256[][2],uint16[],uint256[],uint256[],bool[])"
    );
    assert_eq!(
        CommittedNotes::SIGNATURE,
        "CommittedNotes(uint256,uint256[])"
    );
    assert_eq!(
        CommittedNullifiers::SIGNATURE,
        "CommittedNullifiers(uint256,uint256[])"
    );

    // The enum the indexer dispatches on must still cover them.
    fn _dispatches(e: &CurvyAggregatorAlphaV2Events) -> &'static str {
        match e {
            CurvyAggregatorAlphaV2Events::PendingNotes(_) => "pending",
            CurvyAggregatorAlphaV2Events::CommittedNotes(_) => "committed",
            CurvyAggregatorAlphaV2Events::CommittedNullifiers(_) => "nullifiers",
            _ => "other",
        }
    }
}

#[test]
fn deployment_surface_is_reachable() {
    // Types only, no network: this asserts the paths and generics still exist.
    fn _addresses(a: &CurvyContractAddresses) -> Address {
        a.portal_factory
    }
    fn _ignition_json(a: &CurvyContractAddresses) -> serde_json::Value {
        a.to_ignition_json()
    }
    assert!(DEV_PORTAL_DEPLOYMENT_FEE > U256::ZERO);
}
