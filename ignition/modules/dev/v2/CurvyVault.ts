import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { getNetworkParameter } from "../../utils/parameters";

export default buildModule("CurvyVault", (m) => {
  const implementation = m.contract("CurvyVaultV1", [], { id: "CurvyVaultV1Implementation" });

  const owner = m.getAccount(0);

  const proxy = m.contract("ERC1967Proxy", [
    implementation,
    m.encodeFunctionCall(implementation, "initialize", [owner]),
  ]);

  const curvyVault = m.contractAt("CurvyVaultV1", proxy);

  let previousRegistration: any;
  const erc20Addresses = getNetworkParameter<string[]>("erc20Addresses");

  for (let i = 0; i < erc20Addresses.length; i++) {
    const address = erc20Addresses[i];

    const after = [];
    if (previousRegistration) {
      after.push(previousRegistration);
    }

    previousRegistration = m.call(curvyVault, "registerToken", [address], {
      id: `RegisterVaultToken_${i}`,
      after,
    });
  }

  return { implementation, proxy, curvyVault };
});
