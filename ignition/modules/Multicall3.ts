import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("Multicall3", (m) => {
  const multicall3 = m.contract("Multicall3");

  return { multicall3 };
});
