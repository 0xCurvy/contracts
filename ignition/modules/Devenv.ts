import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import CurvyAggregator from "./CurvyAggregator";
import fs from "node:fs";

const DEPOSIT_AMOUNT = 10n * 10n ** 18n;

export default buildModule("Devenv", (m) => {
  // Deploy aggregator and ERC1155
  const { metaERC20Wrapper } = m.useModule(CurvyAggregator);

  // Deploy multicall
  const multicall3 = m.contract("Multicall3");

  // Deploy mock erc20
  const erc20Mock = m.contract("ERC20Mock");

  const deployer = m.getAccount(0);

  const mintErc20 = m.call(erc20Mock, "mockMint", [deployer, DEPOSIT_AMOUNT]);

  const approval = m.call(erc20Mock, "approve", [metaERC20Wrapper, DEPOSIT_AMOUNT], {
    after: [mintErc20],
  });

  m.call(metaERC20Wrapper, "deposit", [erc20Mock, deployer, DEPOSIT_AMOUNT / 2n], {
    after: [approval],
    id: "deposit1",
  });

  m.call(metaERC20Wrapper, "deposit", ["0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", deployer, DEPOSIT_AMOUNT / 2n], {
    value: DEPOSIT_AMOUNT / 2n,
    id: "deposit2",
  });

  const addresses = JSON.parse(fs.readFileSync("../devenv/addresses.json", "utf-8"));
  for (const userAddresses of addresses) {
    // First address gets ETH
    m.send(`Send_ETH_${userAddresses[0]}`, userAddresses[0], DEPOSIT_AMOUNT, undefined, { from: deployer });

    // Second just gets mock ERC20
    m.call(erc20Mock, "mockMint", [userAddresses[1], DEPOSIT_AMOUNT], { id: `Mint_ERC20_${userAddresses[1]}` });

    // Third gets nothing
  }
  return { erc20Mock, multicall3 };
});