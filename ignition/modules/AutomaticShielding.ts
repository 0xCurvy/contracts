import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import CurvyAggregatorAlphaModule from "./CurvyAggregatorAlpha";

const DEPOSIT_AMOUNT = 1000n * 10n ** 18n;

export default buildModule("AutomaticShieldingModule", (m) => {
  // Deploy aggregator and Vault
  const { curvyVault, curvyAggregatorAlphaV2 } = m.useModule(CurvyAggregatorAlphaModule);

  const noteDeployerFactory = m.contract("NoteDeployerFactory", [curvyAggregatorAlphaV2, curvyVault], {});

  // Deploy mock erc20
  const erc20Mock = m.contract("ERC20Mock");

  const deployer = m.getAccount(0);

  const userAddress = "0x0eeCE19240e3A8826d92da5f4D31581a1DC97779";

  m.send(`Send_ETH`, userAddress, DEPOSIT_AMOUNT, undefined, { from: deployer });

  m.call(erc20Mock, "mockMint", [userAddress, DEPOSIT_AMOUNT], { id: `Mint_ERC20` });

  m.call(curvyVault, "registerToken", [erc20Mock], { id: "Register_MockERC20" });

  return { noteDeployerFactory, curvyVault, curvyAggregatorAlphaV2, erc20Mock };
});
