import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("LegacyPortalModule", (m) => {
  const legacyPortal = m.contract("LegacyPortal", [], { id: "LegacyPortal" });

  return { legacyPortal };
});
