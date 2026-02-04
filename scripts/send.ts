import { network } from "hardhat";
import { parseEther } from "viem";

const { viem } = await network.connect({ network: "anvil" });

const [walletClient] = await viem.getWalletClients();
const publicClient = await viem.getPublicClient();

const hash = await walletClient.sendTransaction({
  to: "0x71574e2f689e5155bbb0339c4563e27dd01da512",
  value: parseEther("1"),
});

const receipt = await publicClient.waitForTransactionReceipt({ hash });

console.dir(receipt);
