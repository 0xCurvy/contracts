import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("AutomaticShieldingModule", (m) => {
  const owner = m.getAccount(0);

  const noteDeployerFactory = m.contract("NoteDeployerFactory", [owner], {
    id: "NoteDeployerFactory",
  });

  // Valid for Ethereum, Optimism, Arbitrum, Polygon, Avalanche
  // Check for other networks at https://docs.li.fi/introduction/lifi-architecture/smart-contract-addresses
  const lifiDiamondAddress = "0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE";

  m.call(noteDeployerFactory, "updateConfig", [
    {
      curvyAggregatorAlphaProxyAddress: "0x0000000000000000000000000000000000000000",
      curvyVaultProxyAddress: "0x0000000000000000000000000000000000000000",
      lifiDiamondAddress: lifiDiamondAddress,
    },
  ]);

  return { noteDeployerFactory };
});
