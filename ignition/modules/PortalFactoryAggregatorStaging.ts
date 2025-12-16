import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("PortalFactoryAggregatorModule", (m) => {
  const owner = m.getAccount(0);

  const curvyVaultProxyAddress = "0xB61F0c208356Df565Bde02dCEd33C896F6b0F939";
  const curvyAggregatorAlphaProxyAddress = "0xE01eE56C613175502c8e677774eaCbBB2738674C";
  const lifiDiamondAddress = "0x0000000000000000000000000000000000000000";

  const portalFactory = m.contract("PortalFactory", [owner], { id: "PortalFactory" });

  m.call(portalFactory, "initializeConfig", [
    curvyVaultProxyAddress,
    curvyAggregatorAlphaProxyAddress,
    lifiDiamondAddress,
  ]);

  return { portalFactory };
});
