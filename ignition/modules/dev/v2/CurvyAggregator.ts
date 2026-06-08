import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("CurvyAggregator", (m) => {
  const poseidonT4 = m.library("PoseidonT4");

  const implementation = m.contract("CurvyAggregatorV2", [], {
    id: "CurvyAggregatorV2Implementation",
    libraries: { PoseidonT4: poseidonT4 },
  });

  const owner = m.getAccount(0);

  const proxy = m.contract("ERC1967Proxy", [
    implementation,
    m.encodeFunctionCall(implementation, "initialize", [owner]),
  ]);

  const curvyAggregator = m.contractAt("CurvyAggregatorAlphaV2", proxy);

  const insertionVerifier = m.contract("CurvyPendingNotesCommitmentVerifier");
  const aggregationVerifier = m.contract("CurvyAggregationVerifier");
  const withdrawVerifier = m.contract("CurvyWithdrawalVerifier");

  // Pending-notes-commitment: (batchSize=5, treeDepth=30)
  m.call(curvyAggregator, "setPendingNotesCommitmentVerifier", [5, 30, insertionVerifier], {
    id: "Aggregator_SetPendingNotesCommitmentVerifier",
  });
  // Aggregation: (maxInputs=2, maxOutputs=3, treeDepth=30)
  m.call(curvyAggregator, "setAggregationVerifier", [2, 3, 30, aggregationVerifier], {
    id: "Aggregator_SetAggregationVerifier",
  });
  // Withdrawal: (maxInputs=2, treeDepth=30)
  m.call(curvyAggregator, "setWithdrawalVerifier", [2, 30, withdrawVerifier], {
    id: "Aggregator_SetWithdrawalVerifier",
  });

  return {
    implementation,
    proxy,
    curvyAggregator,
  };
});
