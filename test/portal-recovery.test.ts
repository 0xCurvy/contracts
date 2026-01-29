import fs from "node:fs";
import { network } from "hardhat";
import { privateKeyToAccount } from "viem/accounts";
import { expect, test } from "vitest";

test("portal-recovery", async () => {
  // 1. Setup
  const ownerHash = 702705117071108858750548073842146797693190729490869702449519502701872077655n;
  const tokenId = 2n;
  const amount = 2797004n;

  const networkObj = await network.connect({ network: "anvil" });

  const { viem } = networkObj;
  const deployedAddressesPath = "./ignition/deployments/staging_anvil/deployed_addresses.json";
  const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));

  const portalFactoryAddress = deployedAddresses["PortalFactoryAggregatorModule#PortalFactory"];
  if (!portalFactoryAddress) {
    throw new Error("PortalFactory address not found for anvil");
  }

  const erc20MockAddress = deployedAddresses["Devenv#ERC20Mock"];
  if (!erc20MockAddress) {
    throw new Error("ERC20Mock address not found for anvil");
  }

  const portalFactory = await viem.getContractAt("PortalFactory", portalFactoryAddress);
  const erc20Mock = await viem.getContractAt("ERC20Mock", erc20MockAddress);

  const publicClient = await viem.getPublicClient();

  const user = privateKeyToAccount("0x49593edf99c94e11b7e1e6f98387af4b5bb996ee76723f0ab5a658ba643d1058");
  const userClient = await viem.getWalletClient(user.address);

  // 2. Transfer tokens to portal
  const expectedPortalAddress = await portalFactory.read.getPortalAddress([ownerHash, user.address]);

  const { request } = await publicClient.simulateContract({
    account: user,
    address: erc20MockAddress,
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
    args: [expectedPortalAddress, amount],
  });

  const hash = await userClient.writeContract(request);

  const receipt = await publicClient.waitForTransactionReceipt({ hash });

  expect(receipt).toBeDefined();

  // 3. Deploy Portal with INVALID token in Note
  console.log("Deploying Portal with invalid token");
  const deployHash = await portalFactory.write.deployAndShield([
    {
      ownerHash,
      token: tokenId,
      amount: amount,
    },
    user.address,
  ]);

  const deployReceipt = await publicClient.waitForTransactionReceipt({
    hash: deployHash,
  });
  expect(deployReceipt.status).toBe("success");

  const portal = await viem.getContractAt("Portal", expectedPortalAddress);

  const recovery = await portal.read.recovery();
  expect(recovery.toLowerCase()).toBe(user.address.toLowerCase());

  const portalBalance = await erc20Mock.read.balanceOf([expectedPortalAddress]);
  expect(portalBalance).toBe(amount);

  // 4. Recover Funds
  console.log("Recovering funds");
  const recoverHash = await portal.write.recover([erc20Mock.address, user.address], { account: user });

  const recoverReceipt = await publicClient.waitForTransactionReceipt({
    hash: recoverHash,
  });
  expect(recoverReceipt.status).toBe("success");

  // 5. Verify Balance
  const portalBalanceAfter = await erc20Mock.read.balanceOf([expectedPortalAddress]);
  expect(portalBalanceAfter).toBe(0n);

  console.log("Recover successful!");
}, 30_000);
