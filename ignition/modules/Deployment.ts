import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import PortalFactory from "./PortalFactory";
import { getNetworkParameter } from "./utils/parameters";

export default buildModule("DeploymentModule", (m) => {
  const { portalFactory } = m.useModule(PortalFactory);

  const lifiDiamondAddress = getNetworkParameter<`0x{string}`>("lifiDiamondAddress");

  if (!lifiDiamondAddress) {
    throw new Error("Missing lifiDiamondAddress network parameter");
  }

  m.call(portalFactory, "updateConfig", [
    "0x0000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000",
    lifiDiamondAddress,
  ]);

  return { portalFactory };
});
