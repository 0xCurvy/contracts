import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import MetaERC20WrapperModule from "./MetaERC20Wrapper";

export default buildModule("CurvyAggregator", (m) => {
  const poseidonT4 = m.library("PoseidonT4");
  const { metaERC20Wrapper } = m.useModule(MetaERC20WrapperModule);
  const curvyAggregator = m.contract("CurvyAggregator", [metaERC20Wrapper], {
    libraries: {
      PoseidonT4: poseidonT4,
    },
  });

  return { curvyAggregator, metaERC20Wrapper };
});
