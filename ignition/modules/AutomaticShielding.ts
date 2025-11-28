import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import CurvyAggregatorAlphaModule from "./CurvyAggregatorAlpha";

const DEPOSIT_AMOUNT = 1000n * 10n ** 18n;

export default buildModule("AutomaticShieldingModule", (m) => {
  const ownerHash = 702705117071108858750548073842146797693190729490869702449519502701872077655n;
  const token = 2n;
  const amount = 2797004n;
  const salt = "0x1230000000000000000000000000000012300000000000000000000000000001";

  const noteDeployerFactory = m.contract("NoteDeployerFactory", []);

  const { curvyAggregatorAlphaV2, curvyVault } = m.useModule(CurvyAggregatorAlphaModule);

  const erc20Mock = m.contract("ERC20Mock");

  const predictedAddress = m.staticCall(noteDeployerFactory, "getContractAddress", [
    { ownerHash, token, amount },
    curvyAggregatorAlphaV2,
    curvyVault,
    salt,
  ]);

  m.call(erc20Mock, "mockMint", [predictedAddress, DEPOSIT_AMOUNT], { id: `Mint_ERC20` });

  m.call(curvyVault, "registerToken", [erc20Mock], { id: "Register_MockERC20" });

  return { noteDeployerFactory, curvyVault, curvyAggregatorAlphaV2, erc20Mock };
});
