import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("MetaERC20Wrapper", (m) => {
  const metaERC20Wrapper = m.contract("MetaERC20Wrapper", []);

  return { metaERC20Wrapper };
});
