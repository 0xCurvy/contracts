import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("PortalFactoryModule", (m) => {
  const owner = m.getAccount(0);

  const portalFactory = m.contract("PortalFactory", [owner], { id: "PortalFactory" });

  return { portalFactory };
});
