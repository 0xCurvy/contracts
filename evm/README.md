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
    `v1/PortalFactory` (id `PortalFactoryV2`) — the existing V1-era flow (V1 proxies +
    V2 portal factory), still driven by `deploy:staging|production`. Left intact; the
    live V1 proxies are not touched.
- `upgrades/` — post-deployment mutations:
  - `UpgradeProxy` — generic UUPS upgrade for future same-line **V2 → V2.x** impl
    bumps (parameterized by `proxyAddress` + a pre-deployed `newImplementation` +
    optional `reinitCalldata`). NOT a V1→V2 path — V2 is greenfield.
  - `AggregatorVerifiers` — V1 aggregator verifier-config update (run by `update-aggregator:*`).
- `legacy/` — **frozen** audited-V1 launch modules; required only to reconcile the
  existing production/staging journals. Do not edit. See `legacy/README.md`.
- `utils/parameters.ts` — env/`--deployment-id`-driven parameter resolution backed by
  `ignition/network-parameters.json` and `ignition/environment-parameters.json`.

## Common commands

```bash
pnpm build                  # hardhat compile
pnpm deploy:local           # spin up anvil + deploy the local Devenv stack
pnpm deploy:staging         # V1-era flow: ENVIRONMENT=staging, all configured networks
pnpm deploy:production      # V1-era flow: ENVIRONMENT=production, all configured networks
pnpm extract-abis           # write deployed v2 ABIs into packages/sdk
```

### Deploying the standalone V2 (greenfield)

V2 is a fresh, standalone deployment (new proxies, new factory) — it does not
upgrade the live V1 proxies. It lands on the separate `<env>_<network>_v2`
deployment-id namespace across all configured networks: the full stack on the
aggregator chains, and the V2 portal factory (+ LiFi) on every other chain:

```bash
pnpm deploy-v2:staging      # ENVIRONMENT=staging  -> staging_<net>_v2
pnpm deploy-v2:production    # ENVIRONMENT=production -> production_<net>_v2
```

### Upgrading a V2 proxy later (V2 → V2.x)

`upgrades/UpgradeProxy.ts` performs a generic UUPS `upgradeToAndCall`. Deploy the
new implementation first, then point the proxy at it:

```bash
# params file: { "UpgradeProxy": { "proxyAddress": "0x…", "newImplementation": "0x…", "reinitCalldata": "0x" } }
pnpm hardhat ignition deploy ignition/modules/upgrades/UpgradeProxy.ts \
  --deployment-id <env>_<network>_v2 --network <network> --parameters <params.json>
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
