import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import type { Address } from "viem";

export default buildModule("CurvyAggregator", (m) => {
  const poseidonT4 = m.library("PoseidonT4");
  const curvyInsertionVerifier = m.contract("CurvyInsertionVerifier");
  const curvyAggregationVerifier = m.contract("CurvyAggregationVerifier");
  const curvyWithdrawVerifier = m.contract("CurvyWithdrawVerifier");

  const metaERC20Wrapper = m.contract("MetaERC20Wrapper");

  const curvyAggregator = m.contract("CurvyAggregator", [metaERC20Wrapper], {
    libraries: {
      PoseidonT4: poseidonT4,
    },
  });

  const setAggregatorAddress = m.call(metaERC20Wrapper, "setAggregatorContractAddress", [curvyAggregator]);

  const updateConfig = m.call(
    curvyAggregator,
    "updateConfig",
    [
      {
        insertionVerifier: curvyInsertionVerifier,
        aggregationVerifier: curvyAggregationVerifier,
        withdrawVerifier: curvyWithdrawVerifier,
        // When 0x0 is passed, it's not changed
        operator: "0x0000000000000000000000000000000000000000",
        feeCollector: "0x0000000000000000000000000000000000000000",
      },
    ],
    {
      after: [setAggregatorAddress],
    },
  );

  // registering erc20 tokens
  const usdcToken: Address = "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238";
  const linkToken: Address = "0x779877A7B0D9E8603169DdbD7836e478b4624789";

  const registerUSDC = m.call(metaERC20Wrapper, "registerToken", [usdcToken], {
    after: [updateConfig],
    id: `registerUSDC`,
  });

  m.call(metaERC20Wrapper, "registerToken", [linkToken], {
    after: [registerUSDC],
    id: `registerLINK`,
  });

  return { curvyAggregator, metaERC20Wrapper };
});
