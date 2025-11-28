import { network } from "hardhat";
import { expect, test } from "vitest";
import AutomaticShieldingModule from "../ignition/modules/AutomaticShielding";

test("automatic-shielding", async () => {
  const ownerHash = 702705117071108858750548073842146797693190729490869702449519502701872077655n;
  const token = 2n;
  const amount = 2797004n;
  const noteId = 14967077268631546162044198053248993673186354912497893587694799228971941136645n;
  const salt = "0x1230000000000000000000000000000012300000000000000000000000000001";

  const { ignition, viem } = await network.connect();

  const { noteDeployerFactory, curvyVault, curvyAggregatorAlphaV2, erc20Mock } =
    await ignition.deploy(AutomaticShieldingModule);

  const noteDeployerAddress = await noteDeployerFactory.read.getContractAddress([
    {
      ownerHash,
      token,
      amount,
    },
    curvyAggregatorAlphaV2.address,
    curvyVault.address,
    salt,
  ]);

  const depositedAmount = 2797004n;

  const tokenIdOfErc20Mock = await curvyVault.read.getTokenId([erc20Mock.address]);
  expect(tokenIdOfErc20Mock).toBe(2n);

  const vaultErc20MockBalanceBeforeDeposit = await curvyVault.read.balanceOf([noteDeployerAddress, tokenIdOfErc20Mock]);
  expect(vaultErc20MockBalanceBeforeDeposit).toBe(0n);

  const tokenAddress = await curvyVault.read.getTokenAddress([token]);
  expect(tokenAddress).toBe(erc20Mock.address);

  await noteDeployerFactory.write.deploy([
    {
      ownerHash,
      token,
      amount,
    },
    curvyAggregatorAlphaV2.address,
    curvyVault.address,
    salt,
  ]);

  // check balances after deposit

  const vaultErc20MockBalanceAfterDeposit = await curvyVault.read.balanceOf([noteDeployerAddress, tokenIdOfErc20Mock]);
  expect(vaultErc20MockBalanceAfterDeposit).toBe(0n);

  const vaultErc20MockBalanceOfAggregator = await curvyVault.read.balanceOf([
    curvyAggregatorAlphaV2.address,
    tokenIdOfErc20Mock,
  ]);
  expect(vaultErc20MockBalanceOfAggregator).toBe(depositedAmount);

  // check if note is deposited

  const noteDeposited = await curvyAggregatorAlphaV2.read.noteInQueue([noteId]);
  expect(noteDeposited).toBe(true);

  //   commit deposit batch
}, 600000);
