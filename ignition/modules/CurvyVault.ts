import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("CurvyVault", (m) => {
  const version = process.env["CURVY_VAULT_VERSION"];
  if (!version) {
    throw new Error("CURVY_VAULT_VERSION env variable is not set");
  }

  const implementation = m.contract(`CurvyVaultV${version}`, []);

  const owner = m.getAccount(0);

  const proxy = m.contract("ERC1967Proxy", [
    implementation,
    m.encodeFunctionCall(implementation, "initialize", [owner]),
  ]);

  const curvyVault = m.contractAt(`CurvyVaultV${version}`, proxy, { id: "CurvyVault" });

  return { implementation, proxy, curvyVault };
});
