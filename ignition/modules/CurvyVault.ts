import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("CurvyVault", (m) => {
  const implementation = m.contract("CurvyVaultV1", [], { id: "CurvyVaultV1Implementation" });

  const owner = m.getAccount(0);

  const proxy = m.contract("ERC1967Proxy", [
    implementation,
    m.encodeFunctionCall(implementation, "initialize", [owner]),
  ]);

  const curvyVault = m.contractAt("CurvyVaultV1", proxy);

  return { implementation, proxy, curvyVault };
});
