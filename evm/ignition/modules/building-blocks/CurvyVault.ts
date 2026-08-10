import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { fullyQualifiedName } from "../../../artifact-registry.mjs";
import { getNetworkParameter } from "../utils/parameters";

export default buildModule("CurvyVault", (m) => {
  const implementation = m.contract("CurvyVaultV2", [], { id: "CurvyVaultV2Implementation" });

  const owner = m.getAccount(0);

  // `devenv/ERC1967Proxy.sol` (added later) collides with the OZ proxy by short
  // name, so `m.contract("ERC1967Proxy", …)` is ambiguous (HHE1001). Pin the OZ
  // proxy by fully-qualified name — the one the original deploy used — and keep
  // the explicit id so the deployed-address key stays `CurvyVault#ERC1967Proxy`.
  const proxy = m.contract(
    fullyQualifiedName("ERC1967Proxy"),
    [implementation, m.encodeFunctionCall(implementation, "initialize", [owner])],
    { id: "ERC1967Proxy" },
  );

  const curvyVault = m.contractAt("CurvyVaultV2", proxy);

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
