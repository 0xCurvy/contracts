import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DEPOSIT_AMOUNT = 10n * 10n ** 18n;

export default buildModule("ERC20", (m) => {
  const deployer = m.getAccount(0);

  const erc20Mock = m.contract("ERC20Mock");
  const metaERC20Wrapper = m.contract("MetaERC20Wrapper");

  const mint = m.call(erc20Mock, "mockMint", [deployer, DEPOSIT_AMOUNT]);

  const approval = m.call(erc20Mock, "approve", [metaERC20Wrapper, DEPOSIT_AMOUNT], {
    after: [mint],
  });

  // 6. Deposit the mock tokens into the wrapper
  m.call(metaERC20Wrapper, "deposit", [erc20Mock, deployer, DEPOSIT_AMOUNT / 2n], {
    after: [approval],
  });

  return { erc20Mock, metaERC20Wrapper };
});
