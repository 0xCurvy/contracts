import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("PortalFactoryModule", (m) => {
  const owner = m.getAccount(0);

  // Ethereum, Optimism, Arbitrum, Polygon, Gnosis, Base, BSC - 0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE
  // Linea - 0xde1e598b81620773454588b85d6b5d4eec32573e
  // Check for other networks at https://docs.li.fi/introduction/lifi-architecture/smart-contract-addresses
  const curvyAggregatorAlphaProxyAddress = "0x0000000000000000000000000000000000000000";
  const curvyVaultProxyAddress = "0x0000000000000000000000000000000000000000";
  const lifiDiamondAddress = "0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE";

  const portalFactory = m.contract("PortalFactory", [owner], { id: "PortalFactory" });

  m.call(portalFactory, "initializeConfig", [
    curvyVaultProxyAddress,
    curvyAggregatorAlphaProxyAddress,
    lifiDiamondAddress,
  ]);

  return { portalFactory };
});
