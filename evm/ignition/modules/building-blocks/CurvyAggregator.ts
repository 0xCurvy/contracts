import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { fullyQualifiedName } from "../../../artifact-registry.mjs";

export default buildModule("CurvyAggregator", (m) => {
  const poseidonT4 = m.library(fullyQualifiedName("PoseidonT4"));

  const implementation = m.contract("CurvyAggregatorAlphaV2", [], {
    id: "CurvyAggregatorV2Implementation",
    libraries: { PoseidonT4: poseidonT4 },
  });

  const owner = m.getAccount(0);

  // `devenv/ERC1967Proxy.sol` (added later) collides with the OZ proxy by short
  // name, so `m.contract("ERC1967Proxy", …)` is ambiguous (HHE1001). Pin the OZ
  // proxy by fully-qualified name — the one the original deploy used — and keep
  // the explicit id so the deployed-address key stays `CurvyAggregator#ERC1967Proxy`.
  const proxy = m.contract(
    fullyQualifiedName("ERC1967Proxy"),
    [implementation, m.encodeFunctionCall(implementation, "initialize", [owner])],
    { id: "ERC1967Proxy" },
  );

  const curvyAggregator = m.contractAt("CurvyAggregatorAlphaV2", proxy);

  const insertionVerifier = m.contract("CurvyPendingNotesCommitmentVerifier");
  const aggregationVerifier = m.contract("CurvyAggregationVerifier");
  const withdrawVerifier = m.contract("CurvyWithdrawalVerifier");

  // Pending-notes-commitment: (batchSize=5, treeDepth=30)
  m.call(curvyAggregator, "setPendingNotesCommitmentVerifier", [5, insertionVerifier], {
    id: "Aggregator_SetPendingNotesCommitmentVerifier",
  });
  // Aggregation: (maxInputs=2, maxOutputs=3, treeDepth=30)
  m.call(curvyAggregator, "setAggregationVerifier", [2, 3, aggregationVerifier], {
    id: "Aggregator_SetAggregationVerifier",
  });
  // Withdrawal: (maxInputs=2, treeDepth=30)
  m.call(curvyAggregator, "setWithdrawalVerifier", [2, withdrawVerifier], {
    id: "Aggregator_SetWithdrawalVerifier",
  });

  return {
    implementation,
    proxy,
    curvyAggregator,
  };
});
