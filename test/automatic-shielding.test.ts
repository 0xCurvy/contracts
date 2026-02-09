import fs from "node:fs";
import { network } from "hardhat";
import { privateKeyToAccount } from "viem/accounts";
import { expect, test } from "vitest";
import type { HexString } from "@0xcurvy/curvy-sdk";

// import PortalFactoryModule from "../ignition/modules/AutomaticShielding";

test("automatic-shielding", async () => {
  const ownerHash = 702705117071108858750548073842146797693190729490869702449519502701872077655n;
  const token = 2n;
  const amount = 2797004n;
  const noteId = 14967077268631546162044198053248993673186354912497893587694799228971941136645n;

  const networkObj = await network.connect({ network: "anvil" });

  // Deploy and run tests
  // const { ignition, viem } = networkObj
  // const { portalFactory, curvyVault, curvyAggregatorAlphaV2, erc20Mock } =
  //   await ignition.deploy(PortalFactoryModule);

  //#region Load deployed contracts

  const { viem } = networkObj;
  const deployedAddressesPath = "./ignition/deployments/local_anvil/deployed_addresses.json";
  const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));

  const vaultAddress = deployedAddresses["CurvyVault#CurvyVault"];
  if (!vaultAddress) {
    throw new Error("MetaERC20Wrapper address not found for anvil");
  }
  const portalFactoryAddress = deployedAddresses["CurvyAggregatorAlpha#PortalFactory"];
  if (!portalFactoryAddress) {
    throw new Error("PortalFactory address not found for anvil");
  }
  const curvyAggregatorAlphaAddress = deployedAddresses["CurvyAggregatorAlpha#CurvyAggregatorAlpha"];
  if (!curvyAggregatorAlphaAddress) {
    throw new Error("CurvyAggregatorAlpha address not found for anvil");
  }

  const erc20MockAddress = deployedAddresses["Devenv#ERC20Mock"];
  if (!erc20MockAddress) {
    throw new Error("ERC20Mock address not found for anvil");
  }

  const curvyVault = await viem.getContractAt("CurvyVault", vaultAddress);
  const portalFactory = await viem.getContractAt("PortalFactory", portalFactoryAddress);
  const curvyAggregatorAlpha = await viem.getContractAt("CurvyAggregatorAlpha", curvyAggregatorAlphaAddress);
  const erc20Mock = await viem.getContractAt("ERC20Mock", erc20MockAddress);

  //#endregion

  const tokenIdOfErc20Mock = await curvyVault.read.getTokenId([erc20Mock.address]);
  expect(tokenIdOfErc20Mock).toBe(2n);

  const tokenAddress = await curvyVault.read.getTokenAddress([token]);
  expect(tokenAddress).toBe(erc20Mock.address);

  // User's wallet, random generated - this is the account: 0x0eeCE19240e3A8826d92da5f4D31581a1DC97779
  const user = privateKeyToAccount("0x49593edf99c94e11b7e1e6f98387af4b5bb996ee76723f0ab5a658ba643d1058");
  const userClient = await viem.getWalletClient(user.address);

  const publicClient = await viem.getPublicClient();

  const portalAddress = await portalFactory.read.getPortalAddress([ownerHash]);

  const { request } = await publicClient.simulateContract({
    account: user,
    address: tokenAddress as HexString,
    abi: [
      {
        inputs: [
          {
            internalType: "address",
            name: "to",
            type: "address",
          },
          {
            internalType: "uint256",
            name: "value",
            type: "uint256",
          },
        ],
        name: "transfer",
        outputs: [
          {
            internalType: "bool",
            name: "",
            type: "bool",
          },
        ],
        stateMutability: "nonpayable",
        type: "function",
      },
    ],
    functionName: "transfer",
    args: [portalAddress, amount],
  });

  const hash = await userClient.writeContract(request);

  const receipt = await publicClient.waitForTransactionReceipt({ hash });

  expect(receipt).toBeDefined();

  const deployHash = await portalFactory.write.deployAndShield([
    {
      ownerHash,
      token,
      amount,
    },
  ]);

  const deployReceipt = await publicClient.waitForTransactionReceipt({ hash: deployHash });

  expect(deployReceipt).toBeDefined();

  // check balances after deposit

  const depositFee = await curvyVault.read.depositFee() as bigint;
  const expectedAmountMinusFees = amount - (amount * depositFee) / 10000n;

  const vaultErc20MockBalanceOfAggregator = await curvyVault.read.balanceOf([
    curvyAggregatorAlphaAddress,
    tokenIdOfErc20Mock,
  ]);
  expect(vaultErc20MockBalanceOfAggregator).toBe(expectedAmountMinusFees);

  // check if note is deposited

  const noteDeposited = await curvyAggregatorAlpha.read.noteInQueue([noteId]);
  expect(noteDeposited).toBe(true);
});
