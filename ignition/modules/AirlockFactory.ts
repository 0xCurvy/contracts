import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("AirlockFactoryModule", (m) => {
  const owner = m.getAccount(0);

  // Valid for Ethereum, Optimism, Arbitrum, Polygon, Avalanche
  // Check for other networks at https://docs.li.fi/introduction/lifi-architecture/smart-contract-addresses
  const lifiDiamondAddress = "0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE";

  const airlockFactory = m.contract("AirlockFactory", [owner], { id: "AirlockFactory" });

  m.call(airlockFactory, "initializeConfig", [
    "0x0000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000",
    lifiDiamondAddress,
  ]);

  return { airlockFactory };
});
