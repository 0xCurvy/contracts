import { network } from "hardhat";
import { privateKeyToAccount } from "viem/accounts";
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

  const tokenIdOfErc20Mock = await curvyVault.read.getTokenId([erc20Mock.address]);
  expect(tokenIdOfErc20Mock).toBe(2n);

  const tokenAddress = await curvyVault.read.getTokenAddress([token]);
  expect(tokenAddress).toBe(erc20Mock.address);

  // User's wallet, random generated - this is the account: 0x0eeCE19240e3A8826d92da5f4D31581a1DC97779
  const user = privateKeyToAccount("0x49593edf99c94e11b7e1e6f98387af4b5bb996ee76723f0ab5a658ba643d1058");
  const userClient = await viem.getWalletClient(user.address);

  // For general RPC reads
  const publicClient = await viem.getPublicClient();

  const noteDeployerAddress = await noteDeployerFactory.read.getContractAddress([ownerHash, salt]);

  // Opcionalno ali preporučeno: Simulacija pre slanja (Gas estimation & error check)
  const { request } = await publicClient.simulateContract({
    account: user,
    address: tokenAddress,
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
    args: [noteDeployerAddress, amount],
  });

  const hash = await userClient.writeContract(request);

  console.log(`Transakcija poslata! Hash: ${hash}`);

  const receipt = await publicClient.waitForTransactionReceipt({ hash });

  console.log(`Transakcija potvrđena u bloku: ${receipt.blockNumber}`);

  await noteDeployerFactory.write.deploy([
    {
      ownerHash,
      token,
      amount,
    },
    salt,
  ]);

  // check balances after deposit

  const depositFee = await curvyVault.read.depositFee();
  const expectedAmountMinusFees = amount - (amount * depositFee) / 10000n;

  const vaultErc20MockBalanceOfAggregator = await curvyVault.read.balanceOf([
    curvyAggregatorAlphaV2.address,
    tokenIdOfErc20Mock,
  ]);
  expect(vaultErc20MockBalanceOfAggregator).toBe(expectedAmountMinusFees);

  // check if note is deposited

  const noteDeposited = await curvyAggregatorAlphaV2.read.noteInQueue([noteId]);
  expect(noteDeposited).toBe(true);

  //   commit deposit batch
}, 600000);
