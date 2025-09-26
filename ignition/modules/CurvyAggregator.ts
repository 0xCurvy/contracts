import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import CurvyInsertionVerifierModule from "./CurvyInsertionVerifier";

export default buildModule("CurvyAggregator", (m) => {
  const poseidonT4 = m.library("PoseidonT4");
  const { curvyInsertionVerifier } = m.useModule(CurvyInsertionVerifierModule);

  const metaERC20Wrapper = m.contract("MetaERC20Wrapper");

  const curvyAggregator = m.contract("CurvyAggregator", [metaERC20Wrapper], {
    libraries: {
      PoseidonT4: poseidonT4,
    },
  });

  m.call(metaERC20Wrapper, "setAggregatorContractAddress", [curvyAggregator]);

  m.call(curvyAggregator, "updateConfig", [
    {
      insertionVerifier: curvyInsertionVerifier,
      aggregationVerifier: "0x0000000000000000000000000000000000000000",
      withdrawVerifier: "0x0000000000000000000000000000000000000000",
      operator: "0x0000000000000000000000000000000000000000",
      feeCollector: "0x0000000000000000000000000000000000000000",
    },
  ]);

  return { curvyAggregator, metaERC20Wrapper };
});
