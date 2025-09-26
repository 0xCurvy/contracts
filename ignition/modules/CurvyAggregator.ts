import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import CurvyInsertionVerifierModule from "./CurvyInsertionVerifier";
import ERC20 from "./ERC20";

export default buildModule("CurvyAggregator", (m) => {
  const poseidonT4 = m.library("PoseidonT4");
  const { erc20Mock, metaERC20Wrapper } = m.useModule(ERC20);
  const { curvyInsertionVerifier } = m.useModule(CurvyInsertionVerifierModule);

  const curvyAggregator = m.contract("CurvyAggregator", [metaERC20Wrapper], {
    libraries: {
      PoseidonT4: poseidonT4,
    },
  });

  m.call(metaERC20Wrapper, "setAggregatorContractAddress", [curvyAggregator]);

  m.call(curvyAggregator, "updateConfig", [
    {
      insertionVerifier: curvyInsertionVerifier,
      aggregationVerifier: "0x0000000000000000000000000000000000000000",
      withdrawVerifier: "0x0000000000000000000000000000000000000000",
      operator: "0x0000000000000000000000000000000000000000",
      feeCollector: "0x0000000000000000000000000000000000000000",
    },
  ]);

  return { curvyAggregator, metaERC20Wrapper, erc20Mock };
});
