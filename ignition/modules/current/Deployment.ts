import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { getAddressParameter } from "../utils/parameters";
import PortalFactoryV2 from "./PortalFactory";

export default buildModule("DeploymentV2", (m) => {
  const { portalFactory } = m.useModule(PortalFactoryV2);

  const lifiDiamondAddress = getAddressParameter("lifiDiamondAddress", "network");

  m.call(portalFactory, "updateConfig", [
    "0x0000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000",
    lifiDiamondAddress,
  ]);

  return { portalFactory };
});
