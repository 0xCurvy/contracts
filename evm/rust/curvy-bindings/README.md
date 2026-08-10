# curvy-bindings

Alloy bindings and local deployment helpers for the Curvy v2 contract suite.

This crate is intentionally small: contract bindings, typed addresses, the localnet
deployment constants, and `deploy_for_testing`.

```
curvy-bindings/
  src/artifacts/*.json   vendored Hardhat artifacts the bindings expand from
  src/codegen/mod.rs     one `alloy::sol!` per contract
  src/config.rs          typed addresses, instances, deployment, and verification
  src/constants.rs       localnet deployment and circuit configuration constants
  artifact-manifest.json source revision, toolchain, and artifact hashes
```

Usage:

```rust
let curvy = CurvyContractInstances::deploy_for_testing(provider.clone(), deployer).await?;
let addresses = curvy.get_contract_addresses();
```

`deploy_for_testing` is for Anvil and development environments only. It uses embedded
development funding, token, fee, and fee-note-key values.


The crate is released under GPL-3.0-only. Upstream component licenses and the
production legal-review items remain recorded in `THIRD_PARTY_NOTICES.md`.

## Provenance

The bindings are expanded from the **Hardhat artifacts of the validated Ignition deploy
pipeline**, vendored in `src/artifacts/`. The bytecode you deploy through this crate is
bit-for-bit what that pipeline ships — not a second, independent build of the same
sources. `artifact-manifest.json` records the source commit, the compiler settings, and
a SHA-256 of every vendored artifact.

## Library linking (PoseidonT4)

`CurvyAggregatorAlphaV2` links the `PoseidonT4` library, so its creation bytecode still
carries solc's `__$…$__` placeholder and the generated module exposes **no `BYTECODE`
constant** — it is bound with `ignore_unlinked`. `deploy_for_testing` handles this for
you: it deploys `PoseidonT4` first and substitutes the 20-byte placeholder with the
resulting address. If you deploy the aggregator yourself, use
`constants::CURVY_AGGREGATOR_ALPHA_V2_UNLINKED_BYTECODE` and do the same substitution.