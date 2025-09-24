import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("MetaERC20Wrapper", (m) => {
  const metaERC20Wrapper = m.contract("MetaERC20Wrapper", ["0x70997970c51812dc3a010c7d01b50e0d17dc79c8"]);

  return { metaERC20Wrapper };
});
