import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import type { Address } from "viem";

export default buildModule("CurvyAggregator", (m) => {
  const curvyInsertionVerifier = m.contract("CurvyInsertionVerifier");
  const curvyAggregationVerifier = m.contract("CurvyAggregationVerifier");
  const curvyWithdrawVerifier = m.contract("CurvyWithdrawVerifier");

  const curvyVault = m.contract("CurvyVault");

  const curvyAggregator = m.contract("CurvyAggregator", []);

  const updateConfig = m.call(curvyAggregator, "updateConfig", [
    {
      // When 0x0 or 0 is passed, it's not changed
      insertionVerifier: curvyInsertionVerifier,
      aggregationVerifier: curvyAggregationVerifier,
      withdrawVerifier: curvyWithdrawVerifier,
      curvyVault: curvyVault,
      maxNotesToCommitInDeposit: 0,
      maxAggregations: 0,
      maxWithdrawals: 0,
    },
  ]);

  // registering erc20 tokens
  const usdcToken: Address = "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238";
  const linkToken: Address = "0x779877A7B0D9E8603169DdbD7836e478b4624789";

  const registerUSDC = m.call(curvyVault, "registerToken", [usdcToken], {
    after: [updateConfig],
    id: `registerUSDC`,
  });

  m.call(curvyVault, "registerToken", [linkToken], {
    after: [registerUSDC],
    id: `registerLINK`,
  });

  return { curvyAggregator, curvyVault };
});
