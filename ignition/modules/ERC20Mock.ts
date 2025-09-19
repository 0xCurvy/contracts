import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("ERC20Mock", (m) => {
  const erc20Mock = m.contract("ERC20Mock");

  // Account #0 in hardhat node
  const mockMint = m.call(erc20Mock, "mockMint", ["0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266", "100"]);

  return { erc20Mock };
});
