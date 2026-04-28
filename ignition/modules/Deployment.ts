import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import PortalFactory from "./PortalFactory";
// audit(2026-Q1): No Validation of Address Format - use validated address parameter helper
import { getAddressParameter } from "./utils/parameters";

export default buildModule("DeploymentModule", (m) => {
  const { portalFactory } = m.useModule(PortalFactory);

  // audit(2026-Q1): No Validation of Address Format - validates 0x-prefixed 20-byte hex
  const lifiDiamondAddress = getAddressParameter("lifiDiamondAddress", "network");

  m.call(portalFactory, "updateConfig", [
    "0x0000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000",
    lifiDiamondAddress,
  ]);

  return { portalFactory };
});
