import { network } from "hardhat";
import { parseEther } from "viem";

const { viem } = await network.connect({ network: "anvil" });

const [walletClient] = await viem.getWalletClients();
const publicClient = await viem.getPublicClient();

const hash = await walletClient.sendTransaction({
  to: "0x2e6748c0a0125e78543f2a052a26d742cc453a04",
  value: parseEther("1"),
});

const receipt = await publicClient.waitForTransactionReceipt({ hash });

console.dir(receipt);
