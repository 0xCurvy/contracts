import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import CurvyAggregator from "./CurvyAggregator";

const DEPOSIT_AMOUNT = 10n * 10n ** 18n;

export default buildModule("Devenv", (m) => {
  const { metaERC20Wrapper } = m.useModule(CurvyAggregator);

  const multicall3 = m.contract("Multicall3");

  const erc20Mock = m.contract("ERC20Mock");

  const deployer = m.getAccount(0);

  const mint = m.call(erc20Mock, "mockMint", [deployer, DEPOSIT_AMOUNT]);

  const approval = m.call(erc20Mock, "approve", [metaERC20Wrapper, DEPOSIT_AMOUNT], {
    after: [mint],
  });

  m.call(metaERC20Wrapper, "deposit", [erc20Mock, deployer, DEPOSIT_AMOUNT / 2n], {
    after: [approval],
  });

  return { erc20Mock, multicall3 };
});
