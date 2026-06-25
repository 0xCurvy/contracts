import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import MainDeployment from "../deployments/v1/MainDeployment";

// NOTE: If you are using this module and portal factory v2 is not deployed,
// make sure to revert the portal contracts to v1 and than run deployment scripts

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
