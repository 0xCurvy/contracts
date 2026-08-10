# Third-party and generated artifact inventory

This crate is licensed under GPL-3.0-only and ships compiled contract artifacts (ABI and
bytecode) derived from the components below, which its bindings expand at compile time.
Preserve this inventory and complete the upstream-license review before production
distribution. This inventory is not a separate license grant.

| Component | Source | Declared license |
|---|---|---|
| Curvy v2 aggregator, vault, portal, and development token | `packages/contracts/evm/src/v2`, `devenv/ERC20Mock.sol` | Apache-2.0 |
| Groth16 verifier contracts | `src/v2/aggregator-alpha/verifiers` | GPL-3.0 |
| Verifier interface | `src/v2/aggregator-alpha/verifiers/ICurvyVerifiers.sol` | BUSL-1.1 |
| PoseidonT4 | `src/v2/utils/PoseidonT4.sol` | MIT |
| CreateX interface and signed deployment transaction | `src/v2/utils/ICreateX.sol`, `scripts/devenv.ts` | AGPL-3.0-only; confirm transaction redistribution |
| OpenZeppelin ERC1967Proxy | `@openzeppelin/contracts` 5.4.0 | MIT |
| Multicall3 | `devenv/Multicall3.sol` | MIT |

The exact source commit and generated-file hashes are recorded in
`artifact-manifest.json`.
