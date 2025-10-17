import fs from "node:fs";
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import CurvyAggregator from "./CurvyAggregator";

const DEPOSIT_AMOUNT = 1000n * 10n ** 18n;

export default buildModule("Devenv", (m) => {
  // Deploy aggregator and ERC1155
  const { metaERC20Wrapper } = m.useModule(CurvyAggregator);

  // Deploy multicall
  const multicall3 = m.contract("Multicall3");

  // Deploy mock erc20
  const erc20Mock = m.contract("ERC20Mock");

  const deployer = m.getAccount(0);

  m.call(metaERC20Wrapper, "deposit", ["0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", deployer, DEPOSIT_AMOUNT / 2n], {
    value: DEPOSIT_AMOUNT / 2n,
    id: "depositETH",
  });

  const mintErc20 = m.call(erc20Mock, "mockMint", [deployer, DEPOSIT_AMOUNT]);

  const approval = m.call(erc20Mock, "approve", [metaERC20Wrapper, DEPOSIT_AMOUNT], {
    after: [mintErc20],
  });

  const registerERC20Mock = m.call(metaERC20Wrapper, "registerToken", [erc20Mock], {
    after: [approval],
  });

  m.call(metaERC20Wrapper, "deposit", [erc20Mock, deployer, DEPOSIT_AMOUNT / 2n], {
    after: [registerERC20Mock],
    id: "depositERC20Mock",
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
