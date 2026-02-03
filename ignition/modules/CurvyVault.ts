import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("CurvyVault", (m) => {
  const implementation = m.contract("CurvyVaultV1", [], { id: "CurvyVaultV1Implementation" });

  const owner = m.getAccount(0);

  const proxy = m.contract("ERC1967Proxy", [
    implementation,
    m.encodeFunctionCall(implementation, "initialize", [owner]),
  ]);

  const curvyVaultV1 = m.contractAt("CurvyVaultV1", proxy);

  // This version makes the fees for withdrawal inclusive adds nicer error messages
  const implementationV2 = m.contract("CurvyVaultV2", [], { id: "CurvyVaultV2Implementation" });

  m.call(curvyVaultV1, "upgradeToAndCall", [implementationV2, "0x"]);

  const curvyVaultV2 = m.contractAt("CurvyVaultV2", proxy);

  // This version introduces the origin address checks for compliance
  const implementationV3 = m.contract("CurvyVaultV3", [], { id: "CurvyVaultV3Implementation" });
  m.call(curvyVaultV2, "upgradeToAndCall", [implementationV3, "0x"]);

  const curvyVault = m.contractAt("CurvyVaultV3", proxy);

  return { implementation, proxy, curvyVault };
});
