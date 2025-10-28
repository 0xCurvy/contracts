import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

import CurvyVaultModule from "./CurvyVault";

export default buildModule("CurvyVaultV2", (m) => {
  const { proxy, curvyVault: oldCurvyVault } = m.useModule(CurvyVaultModule);

  const implementation = m.contract("CurvyVaultV2", [], { id: "CurvyVaultV2Implementation" });

  m.call(oldCurvyVault, "upgradeToAndCall", [implementation, "0x"]);

  const curvyVault = m.contractAt("CurvyVaultV2", proxy);

  return { implementation, proxy, curvyVault };
});
