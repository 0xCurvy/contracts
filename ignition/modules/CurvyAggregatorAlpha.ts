import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("CurvyAggregatorAlpha", (m) => {
  const poseidonT4 = m.library("PoseidonT4");

  const implementation = m.contract("CurvyAggregatorAlphaV1", [], {
    id: "CurvyAggregatorAlphaV1Implementation",
    libraries: { PoseidonT4: poseidonT4 },
  });

  const owner = m.getAccount(0);

  const proxy = m.contract("ERC1967Proxy", [
    implementation,
    m.encodeFunctionCall(implementation, "initialize", [owner]),
  ]);

  const curvyAggregatorAlpha = m.contractAt("CurvyAggregatorAlphaV1", proxy);

  // Production verifier set: depth-30 trees, dimensional suffixes encode circuit shape.
  const insertionVerifier = m.contract("CurvyInsertionVerifierAlpha_2_30");
  const aggregationVerifier = m.contract("CurvyAggregationVerifierAlpha_2_2_2_30");
  const withdrawVerifier = m.contract("CurvyWithdrawVerifierAlpha_2_2_30");

  m.call(curvyAggregatorAlpha, "updateConfig", [
    {
      insertionVerifier,
      aggregationVerifier,
      withdrawVerifier,
      curvyVault: "0x0000000000000000000000000000000000000000",
      portalFactory: "0x0000000000000000000000000000000000000000",
      maxDeposits: 2,
      maxAggregations: 2,
      maxWithdrawals: 2,
    },
  ]);

  return {
    implementation,
    proxy,
    curvyAggregatorAlpha,
    insertionVerifierDepth30: insertionVerifier,
    aggregationVerifierDepth30: aggregationVerifier,
    withdrawVerifierDepth30: withdrawVerifier,
  };
});
