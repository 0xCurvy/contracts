import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import CurvyAggregatorAlpha from "./CurvyAggregatorAlpha";
import CurvyVault from "./CurvyVault";
import PortalFactory from "./PortalFactory";
import TokenBridge from "./TokenBridge";
import { getNetworkParameter } from "./utils/parameters";

export default buildModule("MainDeploymentModule", (m) => {
  // Deploy the contracts
  const { curvyAggregatorAlpha } = m.useModule(CurvyAggregatorAlpha);
  const { curvyVault } = m.useModule(CurvyVault);
  const { portalFactory } = m.useModule(PortalFactory);
  const { tokenBridge } = m.useModule(TokenBridge);

  // Connect Vault to Aggregator
  m.call(curvyVault, "setCurvyAggregatorAddress", [curvyAggregatorAlpha]);

  // Connect Aggregator to Vault
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

  // Connect PortalFactory to LifiDiamond, Aggregator and Vault
  const lifiDiamondAddress = getNetworkParameter<`0x{string}`>("lifiDiamondAddress");

  m.call(portalFactory, "updateConfig", [curvyVault, curvyAggregatorAlpha, lifiDiamondAddress]);

  // Register tokens in vault

  let previousRegistration: any;

  const erc20Addresses = getNetworkParameter<string[]>("erc20Addresses");

  for (let i = 0; i < erc20Addresses.length; i++) {
    const address = erc20Addresses[i];

    const after = [];
    if (previousRegistration) {
      after.push(previousRegistration);
    }

    previousRegistration = m.call(curvyVault, "registerToken", [address], {
      id: `RegisterVaultToken_${i}`,
      after,
    });
  }

  return { curvyAggregatorAlpha, curvyVault, portalFactory, tokenBridge };
});
