import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { getAddressParameter } from "../utils/parameters";
import PortalFactoryV2 from "./PortalFactoryV2";

export default buildModule("MainDeploymentV2", (m) => {
  const vaultProxyAddress = m.getParameter<string>("vaultProxyAddress");
  const aggregatorProxyAddress = m.getParameter<string>("aggregatorProxyAddress");

  const { portalFactory } = m.useModule(PortalFactoryV2);

  const lifiDiamondAddress = getAddressParameter("lifiDiamondAddress", "network");

  const portalFactoryConfig = m.call(
    portalFactory,
    "updateConfig",
    [vaultProxyAddress, aggregatorProxyAddress, lifiDiamondAddress],
    { id: "PortalFactoryConfig" },
  );

  const aggProxyAsV1 = m.contractAt("CurvyAggregatorAlphaV1", aggregatorProxyAddress, {
    id: "AggProxyAsV1",
  });

  m.call(
    aggProxyAsV1,
    "updateConfig",
    [
      {
        insertionVerifier: "0x0000000000000000000000000000000000000000",
        aggregationVerifier: "0x0000000000000000000000000000000000000000",
        withdrawVerifier: "0x0000000000000000000000000000000000000000",
        curvyVault: "0x0000000000000000000000000000000000000000",
        portalFactory,
        maxDeposits: BigInt(0),
        maxAggregations: BigInt(0),
        maxWithdrawals: BigInt(0),
      },
    ],
    { id: "AggConfigForV2Factory", after: [portalFactoryConfig] },
  );

  return { portalFactory, aggregatorProxy: aggProxyAsV1  };
});
