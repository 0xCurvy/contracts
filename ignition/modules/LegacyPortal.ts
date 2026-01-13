import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("LegacyPortalModule", (m) => {
  const owner = m.getAccount(0);

  const legacyPortal = m.contract("LegacyPortal", [owner], { id: "LegacyPortal" });

  return { legacyPortal };
});
