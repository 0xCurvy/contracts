# Curvy Smart Contracts

Hardhat 3 + viem + Hardhat Ignition. Solidity sources live in `src/` (with local
test scaffolding in `devenv/`), deployments are driven by Ignition modules.

For more information visit [Curvy for the curious](https://docs.curvy.box/for-the-curious/).

## Source layout (`src/`)

- `src/v1/`, `src/v2/` — the protocol contracts (vault, aggregator, portal factory, verifiers).
- `src/ens/` — the production ENS CCIP-Read offchain resolver (ERC-3668 + ENSIP-10):
  `OffchainResolver`, `SignatureVerifier`, `IExtendedResolver`, `ISupportsInterface`,
  `SupportsInterface`. Consolidated here from the former standalone
  `packages/ens-resolver/contracts` Hardhat 2 project. (The off-chain gateway
  service in `packages/ens-resolver` consumes hand-written ABIs and is unaffected;
  it only requires that the signing-hash layout, selectors, and `signers` allowlist
  semantics stay stable — which they do.)

## Ignition module structure (`ignition/modules/`)

Ignition reconciles persisted journals by `moduleId#futureId` (the `buildModule("…")`
string + future ids), **independent of file path**. The tree below is organized by
intent; module ids and future ids are stable so all committed
`ignition/deployments/{production,staging}_*` and `local_sepolia` journals still
reconcile.

- `building-blocks/` — reusable, parameterized primitives (the current **V2**
  contracts): `CurvyVault`, `CurvyAggregator`, `PortalFactory`, and `OffchainResolver`.
- `deployments/` — composition modules wired into the deploy scripts, grouped by lineage:
  - `dev/Devenv` — full local stack + ENS/multicall/mock scaffolding (run by `deploy:local`).
  - `v2/Core` — **the standalone V2 full stack** (fresh vault + aggregator +
    independent factory, fully wired) for aggregator chains. V2 is greenfield, not
    a V1 upgrade. Run by `deploy-v2:*` on the `<env>_<network>_v2` deployment ids.
  - `v2/PortalDeployment` (id `PortalDeployment`) — portal-factory-only V2 (factory
    + LiFi) for the non-aggregator chains. Also run by `deploy-v2:*`.
  - `v2/PortalFactory` (id `PortalFactoryV2`) — the fresh, independent V2 factory
    (own `create2_salt_v2` → new address), used by both `v2/Core` and `v2/PortalDeployment`.
  - `v1/MainDeployment` (id `MainDeploymentV2`), `v1/Deployment` (id `DeploymentV2`),
    `v1/PortalFactory` (id `PortalFactoryV2`) — the V1-era flow (V1 proxies + V2 portal
    factory). No script drives these any more (`scripts/deploy.ts` is gone); they are
    kept so the live V1 journals still reconcile. The live V1 proxies are not touched.
- `upgrades/` — post-deployment mutations:
  - `UpgradeProxy` — generic UUPS upgrade for future same-line **V2 → V2.x** impl
    bumps (parameterized by `proxyAddress` + a pre-deployed `newImplementation` +
    optional `reinitCalldata`). NOT a V1→V2 path — V2 is greenfield.
  - `AggregatorVerifiers` — V1 aggregator verifier-config update (run by `update-aggregator:*`).
- `legacy/` — **frozen** audited-V1 launch modules; required only to reconcile the
  existing production/staging journals. Do not edit. See `legacy/README.md`.
- `utils/parameters.ts` — env/`--deployment-id`-driven parameter resolution backed by
  `ignition/network-parameters.json` and `ignition/environment-parameters.json`.

## Generated consumers

Two downstream artefacts are generated from the *same* compiled Hardhat output that the
Ignition deploy pipeline ships — so what a consumer calls is what is actually deployed,
not a second independent build of the same sources:

- **TypeScript ABIs** → `packages/@0xcurvy/sdk/src/contracts/evm/abi/`, written by
  `scripts/extract-abis.ts` (`pnpm extract-abis`).
- **Rust bindings** → `rust/curvy-bindings`, a standalone crate published to crates.io
  and consumed by blokli. See `rust/curvy-bindings/README.md`.

`artifact-registry.mjs` is the single source of truth tying the two together: it maps a
logical contract id to its artifact path and fully qualified name. Both extractors and
all Ignition modules resolve through it, so moving a contract is a one-place edit. Keys
are logical ids rather than contract names because the v1/v2 split left several contracts
sharing a short name (three different `PortalFactory.sol`) — and because **Ignition
records the fully qualified name in its journals**, an existing id must never change what
it resolves to.

### Rust bindings (`rust/`)

The crate commits no generated Rust: `src/codegen/mod.rs` is a short set of
`alloy::sol!` invocations that expand the Hardhat artifacts vendored in
`curvy-bindings/src/artifacts/` at compile time. `rust/extract-artifacts.mjs` refreshes
those artifacts and stamps `artifact-manifest.json` (source commit, compiler settings
read from build-info, and a SHA-256 per artifact); `rust/generate.sh` wraps it.

```bash
./rust/generate.sh          # refresh vendored artifacts + re-stamp the manifest
./rust/generate.sh --check  # verify both are up to date (the CI gate)
```

`generate.sh` recompiles with `HARDHAT_DEVENV=true` when `artifacts/devenv/` is empty.
`devenv/**` is only in `paths.sources` under that flag, and every
ordinary Hardhat task — `compile`, `run`, even `ignition visualize` — silently empties
that directory. Don't "fix" a failing `--check` by hand.

## Common commands

```bash
pnpm build                  # hardhat compile
pnpm deploy:local           # spin up anvil + deploy the local Devenv stack
pnpm deploy-v2:staging      # V2 stack: ENVIRONMENT=staging, all configured networks
pnpm deploy-v2:production   # V2 stack: ENVIRONMENT=production, all configured networks
pnpm extract-abis           # write deployed v2 ABIs into packages/@0xcurvy/sdk
pnpm test:solidity          # Solidity tests (test/solidity, Hardhat's EDR runner)
pnpm test                   # TypeScript tests — needs `deploy:local` + `start:anvil` first
```

### Deploying / registering the ENS offchain resolver

```bash
# 1) Deploy the resolver (gatewayUrl + signers via --parameters):
#    params file: { "OffchainResolver": { "gatewayUrl": "https://…", "signers": ["0x…"] } }
pnpm hardhat ignition deploy ignition/modules/building-blocks/OffchainResolver.ts \
  --network <network> --parameters <params.json>

# 2) Point the ENS name's resolver at the deployed address:
CURVY_NETWORK=<network> CURVY_ENS_DOMAIN=curvy.eth \
  OFFCHAIN_RESOLVER=0x… ENS_REGISTRY=0x… pnpm register-resolver
```
