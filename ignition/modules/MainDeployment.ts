import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import CurvyAggregatorAlpha from "./CurvyAggregatorAlpha";
import CurvyVault from "./CurvyVault";
import PortalFactory from "./PortalFactory";
import { getNetworkParameter } from "./utils/parameters";

export default buildModule("MainDeploymentModule", (m) => {
  // Deploy the contracts
  const {
    curvyAggregatorAlpha,
    proxy: curvyAggregatorAlphaProxy,
    withdrawVerifierV3,
    insertionVerifierDepth30,
    aggregationVerifierDepth30,
    withdrawVerifierDepth30
  } = m.useModule(CurvyAggregatorAlpha);
  const { curvyVault, proxy: curvyVaultProxy } = m.useModule(CurvyVault);
  const { portalFactory } = m.useModule(PortalFactory);

  // Connect Vault to Aggregator
  m.call(curvyVault, "setCurvyAggregatorAddress", [curvyAggregatorAlpha]);

  // Connect Aggregator to Vault
  m.call(curvyAggregatorAlpha, "updateConfig", [
    {
      insertionVerifier: "0x0000000000000000000000000000000000000000",
      aggregationVerifier: "0x0000000000000000000000000000000000000000",
      withdrawVerifier: withdrawVerifierV3,
      curvyVault: curvyVaultProxy,
      portalFactory: portalFactory,
      maxDeposits: BigInt(0),
      maxAggregations: BigInt(0),
      maxWithdrawals: BigInt(0),
    },
  ]);

  // Connect PortalFactory to LifiDiamond, Aggregator and Vault
  const lifiDiamondAddress = getNetworkParameter<`0x{string}`>("lifiDiamondAddress");

  m.call(portalFactory, "updateConfig", [curvyVaultProxy, curvyAggregatorAlphaProxy, lifiDiamondAddress]);

  m.call(curvyAggregatorAlpha, "updateConfig", [
    {
      insertionVerifier: insertionVerifierDepth30,
      aggregationVerifier: aggregationVerifierDepth30,
      withdrawVerifier: withdrawVerifierDepth30,
      curvyVault: "0x0000000000000000000000000000000000000000",
      portalFactory: "0x0000000000000000000000000000000000000000",
      maxDeposits: BigInt(0),
      maxAggregations: BigInt(0),
      maxWithdrawals: BigInt(0),
    },
  ], {
    id: "CurvyAggregator_VerifiersDepth30Update" 
  });

  return { curvyAggregatorAlpha, curvyVault, portalFactory };
});
