import fs from "node:fs";
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
// import AutomaticShieldingModule from "./AutomaticShielding";
import CurvyAggregatorAlphaModule from "./CurvyAggregatorAlpha";

const DEPOSIT_AMOUNT = 1000n * 10n ** 18n;

export default buildModule("Devenv", (m) => {
  // Deploy aggregator and Vault
  const { curvyVault } = m.useModule(CurvyAggregatorAlphaModule);

  // Deploy multicall
  const multicall3 = m.contract("Multicall3");

  // Deploy mock erc20
  const erc20Mock = m.contract("ERC20Mock");

  const deployer = m.getAccount(0);

  const addresses = JSON.parse(fs.readFileSync("../devenv/addresses.json", "utf-8"));
  for (const userAddresses of addresses) {
    // First address gets ETH
    m.send(`Send_ETH_${userAddresses[0]}`, userAddresses[0], DEPOSIT_AMOUNT, undefined, { from: deployer });

    // Second just gets mock ERC20
    m.call(erc20Mock, "mockMint", [userAddresses[1], DEPOSIT_AMOUNT], { id: `Mint_ERC20_${userAddresses[1]}` });

    // Third gets nothing
  }

  m.call(curvyVault, "registerToken", [erc20Mock], { id: "Register_MockERC20" });

  const userAddressForAutomaticShielding = "0x0eeCE19240e3A8826d92da5f4D31581a1DC97779";

  m.send(`Send_ETH_${userAddressForAutomaticShielding}`, userAddressForAutomaticShielding, DEPOSIT_AMOUNT, undefined, {
    from: deployer,
  });
  m.call(erc20Mock, "mockMint", [userAddressForAutomaticShielding, DEPOSIT_AMOUNT], {
    id: `Mint_ERC20_${userAddressForAutomaticShielding}`,
  });

  return { erc20Mock, multicall3 };
});
