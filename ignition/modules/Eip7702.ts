import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import CurvyAggregatorAlphaModule from "./CurvyAggregatorAlpha";

const DEPOSIT_AMOUNT = 1000n * 10n ** 18n;

export default buildModule("Eip7702", (m) => {
  // Deploy aggregator and Vault
  const { curvyVault } = m.useModule(CurvyAggregatorAlphaModule);

  // Deploy multicall
  const multicall3 = m.contract("Multicall3");

  // Deploy mock erc20
  const erc20Mock = m.contract("ERC20Mock");

  const deployer = m.getAccount(0);

  const userAddress = "0x0eeCE19240e3A8826d92da5f4D31581a1DC97779";

  const tokenMover = m.contract("TokenMover");

  m.call(erc20Mock, "mockMint", [userAddress, DEPOSIT_AMOUNT], { id: `Mint_ERC20` });

  m.call(curvyVault, "registerToken", [erc20Mock], { id: "Register_MockERC20" });

  return { erc20Mock, multicall3, tokenMover, curvyVault };
});
