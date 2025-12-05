import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import curvyVaultModule from "./CurvyVault";

export default buildModule("CurvyAggregatorAlpha", (m) => {
  const poseidonT4 = m.library("PoseidonT4");
  const implementation = m.contract("CurvyAggregatorAlphaV1", [], {
    id: "CurvyAggregatorAlphaV1Implementation",
    libraries: {
      PoseidonT4: poseidonT4,
    },
  });

  const owner = m.getAccount(0);

  const { curvyVault } = m.useModule(curvyVaultModule);

  const proxy = m.contract("ERC1967Proxy", [
    implementation,
    m.encodeFunctionCall(implementation, "initialize", [owner, curvyVault]),
  ]);

  const curvyAggregatorAlpha = m.contractAt(`CurvyAggregatorAlphaV1`, proxy);

  const maxDeposits = 2;
  const maxAggregations = 2;
  const maxWithdrawals = 2;

  const insertionVerifier = m.contract(`CurvyInsertionVerifierAlpha_${maxDeposits}_2`);
  const aggregationVerifier = m.contract(`CurvyAggregationVerifierAlpha_${maxAggregations}_2_2`);
  const withdrawVerifier = m.contract(`CurvyWithdrawVerifierAlpha_${maxWithdrawals}_2`);

  m.call(curvyAggregatorAlpha, "updateConfig", [
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

  m.call(curvyAggregatorAlpha, "upgradeToAndCall", [implementationV2, "0x"]);

  const curvyAggregatorAlphaV2 = m.contractAt("CurvyAggregatorAlphaV2", proxy);

  const noteDeployerFactory = m.contract("NoteDeployerFactory");

  m.call(noteDeployerFactory, "updateConfig", [
    {
      curvyAggregatorAlphaProxyAddress: curvyAggregatorAlphaV2,
      curvyVaultProxyAddress: curvyVault,
      lifiDiamondAddress: "0x0000000000000000000000000000000000000000",
    },
  ]);

  return { implementation, proxy, curvyAggregatorAlphaV2, curvyVault, noteDeployerFactory };
});
