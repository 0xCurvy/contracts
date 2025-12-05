import fs from "node:fs";
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
// import AutomaticShieldingModule from "./AutomaticShielding";
import CurvyAggregatorAlphaModule from "./CurvyAggregatorAlpha";

const DEPOSIT_AMOUNT = 1000n * 10n ** 18n;

export default buildModule("Devenv", (m) => {
  // Deploy aggregator and Vault
  const { curvyVault, curvyAggregatorAlphaV2 } = m.useModule(CurvyAggregatorAlphaModule);

  const noteDeployerFactory = m.contract("NoteDeployerFactory");

  m.call(noteDeployerFactory, "updateConfig", [
    {
      curvyVaultProxyAddress: curvyVault,
      curvyAggregatorAlphaProxyAddress: curvyAggregatorAlphaV2,
      lifiDiamondAddress: "0x0000000000000000000000000000000000000000",
    },
  ]);

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

  return { erc20Mock, multicall3 };
});
