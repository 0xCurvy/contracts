import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("PortalFactoryAggregatorModule", (m) => {
  const owner = m.getAccount(0);

  const curvyVaultProxyAddress = "0xB4BA872fBa00Bc4268067D5DE4223240cEc4B6d5";
  const curvyAggregatorAlphaProxyAddress = "0x9c07E1Ff4f1B96ae609331BAc327FcC2d8563224";
  const lifiDiamondAddress = "0x0000000000000000000000000000000000000000";

  const portalFactory = m.contract("PortalFactory", [owner], { id: "PortalFactory" });

  m.call(portalFactory, "initializeConfig", [
    curvyVaultProxyAddress,
    curvyAggregatorAlphaProxyAddress,
    lifiDiamondAddress,
  ]);

  return { portalFactory };
});
