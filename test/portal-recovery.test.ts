import fs from "node:fs";
import { network } from "hardhat";
import { privateKeyToAccount } from "viem/accounts";
import { expect, test } from "vitest";

test("portal-recovery", async () => {
  // 1. Setup
  const ownerHash = 123456789n;
  const invalidTokenId = 999999n;
  const validTokenId = 2n;
  const amount = 1000000n;

  const networkObj = await network.connect({ network: "anvil" });
  const { viem } = networkObj;

  const deployedAddressesPath = "./ignition/deployments/anvil/deployed_addresses.json";
  const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));

  const portalFactoryAddress = deployedAddresses["CurvyAggregatorAlpha#PortalFactory"];
  if (!portalFactoryAddress) throw new Error("PortalFactory address not found");

  const vaultAddress = deployedAddresses["CurvyVault#CurvyVault"];
  if (!vaultAddress) throw new Error("CurvyVault address not found");

  const erc20MockAddress = deployedAddresses["Devenv#ERC20Mock"];
  if (!erc20MockAddress) throw new Error("ERC20Mock address not found");

  const portalFactory = await viem.getContractAt("PortalFactory", portalFactoryAddress);
  const curvyVault = await viem.getContractAt("CurvyVault", vaultAddress);
  const erc20Mock = await viem.getContractAt("ERC20Mock", erc20MockAddress);

  const publicClient = await viem.getPublicClient();

  const token2Address = await curvyVault.read.getTokenAddress([validTokenId]);
  expect(token2Address).toBe(erc20MockAddress);

  const user = privateKeyToAccount("0x49593edf99c94e11b7e1e6f98387af4b5bb996ee76723f0ab5a658ba643d1058");
  const userClient = await viem.getWalletClient(user.address);

  // 2. Deploy Portal with INVALID token in Note to trigger ShieldingFailed

  const expectedPortalAddress = await portalFactory.read.getPortalAddress([ownerHash, user.address]);

  console.log("Deploying Portal with invalid token to trigger ShieldingFailed...");
  const deployHash = await portalFactory.write.deployAndShield(
    [
      {
        ownerHash,
        token: invalidTokenId,
        amount: amount,
      },
      user.address,
    ],
    { account: user.address },
  );

  const deployReceipt = await publicClient.waitForTransactionReceipt({ hash: deployHash });
  expect(deployReceipt.status).toBe("success");

  const portal = await viem.getContractAt("Portal", expectedPortalAddress);

  const recovery = await portal.read.recovery();
  expect(recovery.toLowerCase()).toBe(user.address.toLowerCase());

  // 3. Send Funds to Portal (simulate stuck funds)
  console.log("Sending funds to Portal...");
  const transferHash = await erc20Mock.write.transfer([expectedPortalAddress, amount], { account: user.address });
  await publicClient.waitForTransactionReceipt({ hash: transferHash });

  const portalBalance = await erc20Mock.read.balanceOf([expectedPortalAddress]);
  expect(portalBalance).toBe(amount);

  // 4. Recover Funds
  console.log("Recovering funds...");
  const recoverHash = await portal.write.recover([erc20MockAddress, user.address], { account: user.address });

  const recoverReceipt = await publicClient.waitForTransactionReceipt({ hash: recoverHash });
  expect(recoverReceipt.status).toBe("success");

  // 5. Verify Balance
  const portalBalanceAfter = await erc20Mock.read.balanceOf([expectedPortalAddress]);
  expect(portalBalanceAfter).toBe(0n);

  console.log("Recover successful!");
});
