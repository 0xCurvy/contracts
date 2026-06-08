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

  m.call(curvyAggregator, "updateConfig", [
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
    curvyAggregator,
  };
});
