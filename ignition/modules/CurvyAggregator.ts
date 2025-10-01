import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("CurvyAggregator", (m) => {
  const poseidonT4 = m.library("PoseidonT4");
  const curvyInsertionVerifier = m.contract("CurvyInsertionVerifier");
  const curvyAggregationVerifier = m.contract("CurvyAggregationVerifier");
  const curvyWithdrawVerifier = m.contract("CurvyWithdrawVerifier");

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
      aggregationVerifier: curvyAggregationVerifier,
      withdrawVerifier: curvyWithdrawVerifier,
      operator: "0x0000000000000000000000000000000000000000", // TODO use or delete
      feeCollector: "0x0000000000000000000000000000000000000000", // TODO use or delete
    },
  ]);

  return { curvyAggregator, metaERC20Wrapper };
});
