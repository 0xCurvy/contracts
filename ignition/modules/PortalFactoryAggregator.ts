import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import curvyAggregatorAlphaModule from "./CurvyAggregatorAlpha";

export default buildModule("PortalFactoryAggregatorModule", (m) => {
  const owner = m.getAccount(0);

  const { curvyVault, curvyAggregatorAlpha } = m.useModule(curvyAggregatorAlphaModule);

  const lifiDiamondAddress = "0x0000000000000000000000000000000000000000";

  const portalFactory = m.contract("PortalFactory", [owner], { id: "PortalFactory" });

  m.call(portalFactory, "initializeConfig", [curvyVault, curvyAggregatorAlpha, lifiDiamondAddress]);

  return { curvyVault, portalFactory };
});
