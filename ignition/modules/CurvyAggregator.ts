import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import MetaERC20WrapperModule from "./MetaERC20Wrapper";
import CurvyInsertionVerifierModule from "./CurvyInsertionVerifier";

export default buildModule("CurvyAggregator", (m) => {
  const poseidonT4 = m.library("PoseidonT4");
  const { metaERC20Wrapper } = m.useModule(MetaERC20WrapperModule);
  const { curvyInsertionVerifier } = m.useModule(CurvyInsertionVerifierModule);

  const curvyAggregator = m.contract("CurvyAggregator", [metaERC20Wrapper], {
    libraries: {
      PoseidonT4: poseidonT4,
    },
  });

  m.call(curvyAggregator, "updateConfig", [{
    insertionVerifier: curvyInsertionVerifier,
    aggregationVerifier: "0x0000000000000000000000000000000000000000",
    withdrawVerifier: "0x0000000000000000000000000000000000000000",
    operator: "0x0000000000000000000000000000000000000000",
    feeCollector: "0x0000000000000000000000000000000000000000",
  }]);

  return { curvyAggregator };
});
