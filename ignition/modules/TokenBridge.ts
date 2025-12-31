import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("TokenBridgeModule", (m) => {
  const lifiDiamondAddress = "0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE";

  const tokenBridge = m.contract("TokenBridge", [lifiDiamondAddress], { id: "TokenBridge" });

  return { tokenBridge };
});
