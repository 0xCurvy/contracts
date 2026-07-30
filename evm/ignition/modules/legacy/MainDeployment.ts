import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
// audit(2026-Q1): No Validation of Address Format - use validated address parameter helper
import { getAddressParameter } from "../utils/parameters";
import PortalFactory from "./PortalFactory";

/**
 * Main-chain deployment for the V1 (out-of-beta) launch.
 *
 * On a chain that already runs the beta vault + aggregator (i.e. the
 * aggregator chain and its testnet — see `legacy-proxy-addresses.json`),
 * this module:
 *
 *  1. Deploys the audited V1 vault implementation and runs
 *     `upgradeToAndCall(impl, bootstrapAccessControl())` on the existing
 *     proxy. The bootstrap is `reinitializer(2)` and seeds OPERATOR_ROLE
 *     and AUTHORITY_ROLE on the current owner; the pre-AC
 *     `_authorizeUpgrade(onlyOwner)` gates the upgrade itself.
 *  2. Same for the audited V1 aggregator (proxy reused, PoseidonT4 library
 *     reused).
 *  3. Deploys a fresh PortalFactory via CreateX (deterministic from
 *     `create2_salt`) and wires it to the freshly-upgraded vault, aggregator,
 *     and the network's LiFi diamond.
 *
 * Greenfield (no existing proxies) main-chain bootstrap is not handled here
 * by design — the building blocks live in `CurvyVault.ts`,
 * `CurvyAggregatorAlpha.ts`, and `PortalFactory.ts` and can be composed when
 * a new aggregator chain is onboarded.
 */
export default buildModule("MainDeployment", (m) => {
  const vaultProxyAddress = m.getParameter<string>("vaultProxyAddress");
  const aggregatorProxyAddress = m.getParameter<string>("aggregatorProxyAddress");
  const poseidonT4Address = m.getParameter<string>("poseidonT4Address");

  // === Vault upgrade ===
  const newVaultImpl = m.contract("CurvyVaultV1", [], {
    id: "CurvyVaultV1Implementation_Audited",
  });

  const vaultProxyAsV1 = m.contractAt("CurvyVaultV1", vaultProxyAddress, {
    id: "VaultProxyAsV1",
  });

  const vaultUpgrade = m.call(
    vaultProxyAsV1,
    "upgradeToAndCall",
    [newVaultImpl, m.encodeFunctionCall(newVaultImpl, "bootstrapAccessControl", [])],
    { id: "VaultUpgradeToV1" },
  );

  // === Aggregator upgrade ===
  const poseidonT4 = m.contractAt("src/v1/aggregator-alpha/utils/PoseidonT4.sol:PoseidonT4", poseidonT4Address, {
    id: "PoseidonT4Existing",
  });

  const newAggImpl = m.contract("CurvyAggregatorAlphaV1", [], {
    id: "CurvyAggregatorAlphaV1Implementation_Audited",
    libraries: { PoseidonT4: poseidonT4 },
  });

  const aggProxyAsV1 = m.contractAt("CurvyAggregatorAlphaV1", aggregatorProxyAddress, {
    id: "AggProxyAsV1",
  });

  const aggUpgrade = m.call(
    aggProxyAsV1,
    "upgradeToAndCall",
    [newAggImpl, m.encodeFunctionCall(newAggImpl, "bootstrapAccessControl", [])],
    { id: "AggUpgradeToV1" },
  );

  // === PortalFactory fresh deploy ===
  // CreateX gives a deterministic address from `create2_salt`; audit-fixed
  // bytecode means a different address than the beta factory, so all V1
  // portals are CREATE2-derived from the new factory address.
  const { portalFactory } = m.useModule(PortalFactory);

  // audit(2026-Q1): No Validation of Address Format - validates 0x-prefixed 20-byte hex
  const lifiDiamondAddress = getAddressParameter("lifiDiamondAddress", "network");

  m.call(portalFactory, "updateConfig", [vaultProxyAddress, aggregatorProxyAddress, lifiDiamondAddress], {
    id: "PortalFactoryConfig",
    after: [vaultUpgrade, aggUpgrade],
  });

  m.call(aggProxyAsV1, "updateConfig", [
    {
      insertionVerifier: "0x0000000000000000000000000000000000000000",
      aggregationVerifier: "0x0000000000000000000000000000000000000000",
      withdrawVerifier: "0x0000000000000000000000000000000000000000",
      curvyVault: "0x0000000000000000000000000000000000000000",
      portalFactory,
      maxDeposits: BigInt(0),
      maxAggregations: BigInt(0),
      maxWithdrawals: BigInt(0),
    },
  ]);

  return { newVaultImpl, newAggImpl, portalFactory, aggregatorProxy: aggProxyAsV1 };
});
