import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/**
 * Generic UUPS proxy upgrade — points an existing Curvy **V2** proxy (vault or
 * aggregator) at an ALREADY-DEPLOYED new implementation, optionally running a
 * reinitializer via `upgradeToAndCall`.
 *
 * This is intentionally version-agnostic: it does NOT deploy the implementation
 * (impl contract names are compile-time, and the aggregator impl needs a linked
 * PoseidonT4). Deploy the new implementation first — e.g. with a versioned
 * building block — then pass its address here. One module covers both the vault
 * and the aggregator because `upgradeToAndCall` comes from the shared
 * `UUPSUpgradeable` base; the `CurvyVaultV2` ABI is used only to expose that
 * selector.
 *
 * IMPORTANT: this is for same-line **V2 → V2.x** implementation bumps only. It is
 * NOT the V1 → V2 path — V2 is a standalone greenfield deployment
 * (`deployments/v2/Core.ts`), so the live V1 proxies are never upgraded.
 *
 * Parameters (`--parameters`):
 *   { "UpgradeProxy": { "proxyAddress": "0x…", "newImplementation": "0x…", "reinitCalldata": "0x" } }
 *
 * `_authorizeUpgrade` on the V2 contracts is gated by `AUTHORITY_ROLE`, so the
 * deploying account must hold that role on the proxy.
 */
export default buildModule("UpgradeProxy", (m) => {
  const proxyAddress = m.getParameter<string>("proxyAddress");
  const newImplementation = m.getParameter<string>("newImplementation");
  const reinitCalldata = m.getParameter<string>("reinitCalldata", "0x");

  const proxy = m.contractAt("CurvyVaultV2", proxyAddress, { id: "Proxy" });

  m.call(proxy, "upgradeToAndCall", [newImplementation, reinitCalldata], { id: "Upgrade" });

  return { proxy };
});
