//! Alloy bindings and local deployment helpers for Curvy v2 contracts.

mod codegen;

pub mod config;
pub mod constants;

pub use codegen::*;

pub mod exports {
    pub use alloy;
}

pub use config::{CurvyContractAddresses, CurvyContractInstances};
