import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import CurvyAggregatorAlpha from "./CurvyAggregatorAlpha";
import CurvyVault from "./CurvyVault";
import PortalFactory from "./PortalFactory";

export default buildModule("DeploymentModule", (m) => {
  const { curvyAggregatorAlpha } = m.useModule(CurvyAggregatorAlpha);
  const { curvyVault } = m.useModule(CurvyVault);
  const { portalFactory } = m.useModule(PortalFactory);

  m.call(curvyVault, "setCurvyAggregatorAddress", [curvyAggregatorAlpha]);
  m.call(curvyAggregatorAlpha, "updateConfig", [
    {
      insertionVerifier: "0x0000000000000000000000000000000000000000",
      aggregationVerifier: "0x0000000000000000000000000000000000000000",
      withdrawVerifier: "0x0000000000000000000000000000000000000000",
      curvyVault: curvyVault,
      portalFactory: portalFactory,
      maxDeposits: BigInt(0),
      maxAggregations: BigInt(0),
      maxWithdrawals: BigInt(0),
    },
  ]);

  return { curvyAggregatorAlpha, curvyVault, portalFactory };
});
