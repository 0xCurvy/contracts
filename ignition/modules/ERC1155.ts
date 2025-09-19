import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("ERC1155", (m) => {
  const erc1155 = m.contract("ERC1155Meta");

  return { erc1155 };
});
