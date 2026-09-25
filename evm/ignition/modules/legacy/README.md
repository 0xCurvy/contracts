# `legacy/` — frozen audited-V1 launch modules

These modules deployed the **audited V1** vault + aggregator + portal factory for
the out-of-beta launch. They are **frozen**: do not edit them and do not rename
their `buildModule(...)` ids or future ids.

They are kept because the persisted Ignition journals under
`ignition/deployments/{production,staging}_*` were written (in part) by these exact
modules. Ignition reconciles by `moduleId#futureId`, so these modules must remain
resolvable — with identical ids — for any future `resume`/`verify`/upgrade run
against those live deployment ids.

| File | module id | role |
|------|-----------|------|
| `MainDeployment.ts` | `MainDeployment` | V1 vault+aggregator `upgradeToAndCall(bootstrapAccessControl)` on the existing beta proxies, plus a fresh V1 PortalFactory wired in. Deployed on `{production,staging}_{arbitrum,sepolia}`. |
| `PortalFactory.ts` | `PortalFactory` | Audited **V1** PortalFactory via CreateX. Deployed-address key `PortalFactory#PortalFactory` exists in all 20 production/staging journals. |
| `Deployment.ts` | `DeploymentModule` | Portal-factory-only V1 composition (non-aggregator chains). |

### Relationship to the active modules

- The **current production** path lives in `../deployments/` (`MainDeploymentV2`,
  `DeploymentV2`, `PortalFactoryV2`) and is what `scripts/deploy.ts` runs today.
- The module id `PortalFactory` here is intentionally shared with
  `../building-blocks/PortalFactory.ts` (the **V2** local/greenfield factory).
  They never appear in the same deployment journal, so there is no reconciliation
  collision — the V1 block only reconciles the production/staging journals, the V2
  block only runs under `local_anvil`/greenfield ids.
- New chains and future upgrades should use `../building-blocks/`,
  `../deployments/`, and `../upgrades/` — never these files.
