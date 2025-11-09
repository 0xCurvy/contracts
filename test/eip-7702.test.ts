import { network } from "hardhat";
import { encodeFunctionData } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { expect, test } from "vitest";
import Eip7702Module from "../ignition/modules/Eip7702";

test("eip-7702", async () => {
  const { ignition, viem } = await network.connect();

  const { tokenMover, erc20Mock, curvyVault } = await ignition.deploy(Eip7702Module);

  // How much the user initially has in erc20Mock
  const expectedAmount = 1000n * 10n ** 18n;

  // How much we will charge the user in the currency for gas
  const gasSponsorshipAmount = 10n ** 18n; // e.g. 1 erc20Mock

  // Curvy wallet
  const deployer = privateKeyToAccount("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");
  const deployerClient = await viem.getWalletClient(deployer.address);

  // User's wallet, random generated - this is the account: 0x0eeCE19240e3A8826d92da5f4D31581a1DC97779
  const user = privateKeyToAccount("0x49593edf99c94e11b7e1e6f98387af4b5bb996ee76723f0ab5a658ba643d1058");
  const userClient = await viem.getWalletClient(user.address);

  // For general RPC reads
  const publicClient = await viem.getPublicClient();

  // User signs the authorization
  const authorization = await userClient.signAuthorization({
    account: user,
    contractAddress: tokenMover.address,
  });

  const userEthBalance = await publicClient.getBalance({ address: user.address });
  expect(userEthBalance).toBe(0n);

  const tokenIdOfErc20Mock = await curvyVault.read.getTokenId([erc20Mock.address]);
  expect(tokenIdOfErc20Mock).toBe(2n);

  const vaultErc20MockBalanceBeforeAuthorization = await curvyVault.read.balanceOf([user.address, tokenIdOfErc20Mock]);
  expect(vaultErc20MockBalanceBeforeAuthorization).toBe(0n);

  const mockErc20BalanceBeforeAuthorization = await erc20Mock.read.balanceOf([user.address]);
  expect(mockErc20BalanceBeforeAuthorization).toBe(expectedAmount);

  // Send the authorization transaction from
  const receipt = await deployerClient
    .sendTransaction({
      authorizationList: [authorization],
      data: encodeFunctionData({
        abi: [
          {
            inputs: [
              {
                internalType: "address",
                name: "token",
                type: "address",
              },
            ],
            name: "SafeERC20FailedOperation",
            type: "error",
          },
          {
            inputs: [
              {
                internalType: "address",
                name: "tokenAddress",
                type: "address",
              },
              {
                internalType: "address",
                name: "curvyVaultAddress",
                type: "address",
              },
              {
                internalType: "uint256",
                name: "gasSponsorshipAmount",
                type: "uint256",
              },
            ],
            name: "moveAllTokens",
            outputs: [],
            stateMutability: "nonpayable",
            type: "function",
          },
        ],
        functionName: "moveAllTokens",
        args: [erc20Mock.address, curvyVault.address, gasSponsorshipAmount],
      }),
      to: user.address,
    })
    .then((txHash) =>
      publicClient.waitForTransactionReceipt({
        hash: txHash,
      }),
    );

  // Check that user has Curvy Vault balance decreased by Gas and Curvy fee
  const vaultErc20MockBalanceAfterAuthorization = await curvyVault.read.balanceOf([user.address, tokenIdOfErc20Mock]);
  const depositFee = await curvyVault.read.depositFee();
  const expectedAmountMinusFees = expectedAmount - (expectedAmount * depositFee) / 10000n - gasSponsorshipAmount;
  expect(vaultErc20MockBalanceAfterAuthorization).toBe(expectedAmountMinusFees);

  // The user shouldn't have any ERC-20 balance
  const mockErc20BalanceAfterAuthorization = await erc20Mock.read.balanceOf([user.address]);
  expect(mockErc20BalanceAfterAuthorization).toBe(0n);
}, 600000);
