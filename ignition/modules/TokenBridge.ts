import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { getNetworkParameter } from "./utils/parameters";

export default buildModule("TokenBridgeModule", (m) => {
  const outputBridgelifiDiamondAddress = getNetworkParameter<`0x{string}`>("outputBridgeLifiDiamondAddress");

  const tokenBridge = m.contract("TokenBridge", [outputBridgelifiDiamondAddress], { id: "TokenBridge" });

  return { tokenBridge };
});
