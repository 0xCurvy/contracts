import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("CurvyVault", (m) => {
  const curvyVaultV1 = m.contract("CurvyVaultV1");

  const owner = m.getAccount(0);

  const proxy = m.contract("ERC1967Proxy", [curvyVaultV1, m.encodeFunctionCall(curvyVaultV1, "initialize", [owner])]);

  const curvyVault = m.contractAt("CurvyVaultV1", proxy, { id: "CurvyVault" });

  return { curvyVaultV1, proxy, curvyVault };
});
