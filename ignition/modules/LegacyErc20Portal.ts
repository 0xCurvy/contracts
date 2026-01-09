import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("LegacyErc20PortalModule", (m) => {
  const legacyErc20Portal = m.contract("LegacyErc20Portal", [], { id: "LegacyErc20Portal" });

  return { legacyErc20Portal };
});
