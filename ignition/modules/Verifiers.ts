import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("Verifiers", (m) => {
  const poseidonT4 = m.library("PoseidonT4");
  const curvyInsertionVerifier = m.contract("CurvyInsertionVerifier");
  const curvyAggregationVerifier = m.contract("CurvyAggregationVerifier");
  const curvyWithdrawVerifier = m.contract("CurvyWithdrawVerifier");

  return { curvyInsertionVerifier, curvyAggregationVerifier, curvyWithdrawVerifier };
});
