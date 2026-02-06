import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("CurvyAggregatorAlpha", (m) => {
  const poseidonT4 = m.library("PoseidonT4");
  const implementation = m.contract("CurvyAggregatorAlphaV1", [], {
    id: "CurvyAggregatorAlphaV1Implementation",
    libraries: {
      PoseidonT4: poseidonT4,
    },
  });

  const owner = m.getAccount(0);

  const proxy = m.contract("ERC1967Proxy", [
    implementation,
    m.encodeFunctionCall(implementation, "initialize", [owner, "0x0000000000000000000000000000000000000000"]),
  ]);

  const curvyAggregatorAlphaV1 = m.contractAt(`CurvyAggregatorAlphaV1`, proxy);

  const maxDeposits = 2;
  const maxAggregations = 2;
  const maxWithdrawals = 2;

  const insertionVerifier = m.contract(`CurvyInsertionVerifierAlpha_${maxDeposits}_2`);
  const aggregationVerifier = m.contract(`CurvyAggregationVerifierAlpha_${maxAggregations}_2_2`);
  const withdrawVerifier = m.contract(`CurvyWithdrawVerifierAlpha_${maxWithdrawals}_2`);

  m.call(curvyAggregatorAlphaV1, "updateConfig", [
    {
      insertionVerifier,
      aggregationVerifier,
      withdrawVerifier,
      // Don't change what was set in constructor
      curvyVault: "0x0000000000000000000000000000000000000000",
      maxDeposits,
      maxAggregations,
      maxWithdrawals,
    },
  ]);

  // This implementation fixes the commitWithdrawalBatch to invoke meta tx with type transfer instead of withdraw
  const implementationV2 = m.contract("CurvyAggregatorAlphaV2", [], {
    id: "CurvyAggregatorAlphaV2Implementation",
    libraries: {
      PoseidonT4: poseidonT4,
    },
  });

  m.call(curvyAggregatorAlphaV1, "upgradeToAndCall", [implementationV2, "0x"]);

  const curvyAggregatorAlphaV2 = m.contractAt("CurvyAggregatorAlphaV2", proxy);

  const implementationV3 = m.contract("CurvyAggregatorAlphaV3", [], {
    id: "CurvyAggregatorAlphaV3Implementation",
    libraries: {
      PoseidonT4: poseidonT4,
    },
  });

  m.call(curvyAggregatorAlphaV2, "upgradeToAndCall", [implementationV3, "0x"]);

  const curvyAggregatorAlphaV3 = m.contractAt("CurvyAggregatorAlphaV3", proxy);

  const newInsertionVerifier = m.contract(`CurvyInsertionVerifierAlpha_${maxDeposits}`, [], {
    id: "NewInsertionVerifier_v2",
    after: [curvyAggregatorAlphaV3],
  });

  const newAggregationVerifier = m.contract(`CurvyAggregationVerifierAlpha_${maxAggregations}`, [], {
    id: "NewAggregationVerifier_v2",
    after: [newInsertionVerifier],
  });

  const newWithdrawVerifier = m.contract(`CurvyWithdrawVerifierAlpha_${maxWithdrawals}`, [], {
    id: "NewWithdrawVerifier_v2",
    after: [newAggregationVerifier],
  });

  const updateNewVerifiers = m.call(
    curvyAggregatorAlphaV3,
    "updateConfig",
    [
      {
        insertionVerifier: newInsertionVerifier,
        aggregationVerifier: newAggregationVerifier,
        withdrawVerifier: newWithdrawVerifier,
        curvyVault: "0x0000000000000000000000000000000000000000",
        maxDeposits: 0,
        maxAggregations: 0,
        maxWithdrawals: 0,
      },
    ],
    {
      id: "UpdateConfig_WithNewVerifiers",
      after: [newWithdrawVerifier],
    },
  );

  const implementationV4 = m.contract("CurvyAggregatorAlphaV4", [], {
    id: "CurvyAggregatorAlphaV4Implementation",
    libraries: {
      PoseidonT4: poseidonT4,
    },
    after: [updateNewVerifiers],
  });

  m.call(curvyAggregatorAlphaV3, "upgradeToAndCall", [implementationV4, "0x"]);

  const curvyAggregatorAlpha = m.contractAt("CurvyAggregatorAlphaV4", proxy);

  return { implementation: implementationV4, proxy, curvyAggregatorAlpha };
});
