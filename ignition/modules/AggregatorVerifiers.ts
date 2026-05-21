import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import MainDeployment from "./current/MainDeployment";

export default buildModule("AggregatorVerifiers", (m) => {
  const { aggregatorProxy } = m.useModule(MainDeployment);

  const aggregationVerifier = m.contract("CurvyAggregationVerifierAlpha");

  m.call(aggregatorProxy, "updateConfig", [
    {
      insertionVerifier: "0x0000000000000000000000000000000000000000",
      aggregationVerifier,
      withdrawVerifier: "0x0000000000000000000000000000000000000000",
      curvyVault: "0x0000000000000000000000000000000000000000",
      portalFactory: "0x0000000000000000000000000000000000000000",
      maxDeposits: 0,
      maxAggregations: 0,
      maxWithdrawals: 0,
    },
  ]);

  return {
    aggregatorProxy,
    aggregationVerifier,
  };
});
