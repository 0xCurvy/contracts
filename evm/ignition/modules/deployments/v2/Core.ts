import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import CurvyAggregator from "../../building-blocks/CurvyAggregator";
import CurvyVault from "../../building-blocks/CurvyVault";
import { getAddressParameter } from "../../utils/parameters";
import GreenfieldPortalFactory from "./PortalFactory";

/**
 * Standalone GREENFIELD V2 deployment for production/staging aggregator chains.
 *
 * The V2 contracts changed substantially and are deployed fresh — NOT as an
 * upgrade of the live V1 proxies. This composes the V2 building blocks into a
 * brand-new, self-contained stack:
 *   - a fresh CurvyVaultV2 proxy (+ registered tokens from network-parameters),
 *   - a fresh CurvyAggregatorAlphaV2 proxy (+ PoseidonT4 + verifiers),
 *   - a fresh, independent V2 PortalFactory (own `create2_salt_v2` → new address),
 * then wires them together (vault↔aggregator, factory→vault/aggregator/LiFi).
 *
 * It is the real-network analogue of `Devenv.ts` minus the local ENS/multicall/
 * mock-ERC20/funding scaffolding. Run it on the fresh `<env>_<network>_v2`
 * deployment ids via `scripts/deploy-v2.ts` so the V2 journals stay cleanly
 * separate from the V1 ones.
 */
export default buildModule("Core", (m) => {
  const { curvyVault, proxy: curvyVaultProxy } = m.useModule(CurvyVault);
  const { curvyAggregator, proxy: curvyAggregatorProxy } = m.useModule(CurvyAggregator);
  const { portalFactory } = m.useModule(GreenfieldPortalFactory);

  // Wire vault -> aggregator
  const setVaultAggregator = m.call(curvyVault, "setCurvyAggregatorAddress", [curvyAggregator]);

  // Wire aggregator -> vault + portal factory (verifiers were set by the CurvyAggregator block)
  const wireAggregator = m.call(
    curvyAggregator,
    "updateConfig",
    [
      {
        curvyVault: curvyVaultProxy,
        portalFactory: portalFactory,
      },
    ],
    { id: "Aggregator_WireVaultAndFactory", after: [setVaultAggregator] },
  );

  // Wire portal factory -> vault, aggregator, and the network's LiFi diamond
  const lifiDiamondAddress = getAddressParameter("lifiDiamondAddress", "network");
  m.call(portalFactory, "updateConfig", [curvyVaultProxy, curvyAggregatorProxy, lifiDiamondAddress], {
    id: "PortalFactory_Wire",
    after: [wireAggregator],
  });

  return { curvyVault, curvyAggregator, portalFactory };
});
