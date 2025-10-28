import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import curvyVaultModule from "./CurvyVault";

export default buildModule("CurvyAggregatorAlphaV1", (m) => {
  const implementation = m.contract("CurvyAggregatorAlphaV1", [], { id: "CurvyAggregatorAlphaV1Implementation" });

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

  const insertionVerifier = m.contract(`CurvyInsertionVerifierAlpha${maxDeposits}_2`);
  const aggregationVerifier = m.contract(`CurvyAggregationVerifierAlpha_${maxAggregations}_2_2`);
  const withdrawVerifier = m.contract(`CurvyWithdrawVerifierAlpha_${maxWithdrawals}_2`);

  m.call(curvyAggregatorAlpha, "updateConfig", [
    {
      insertionVerifier,
      aggregationVerifier,
      withdrawVerifier,
      curvyVault: "0x0",
      maxDeposits,
      maxAggregations,
      maxWithdrawals,
    },
  ]);

  return { implementation, proxy, curvyAggregatorAlpha };
});
