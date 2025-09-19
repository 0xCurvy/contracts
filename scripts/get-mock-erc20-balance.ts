import * as fs from "node:fs";
import { network } from "hardhat";

const { viem } = await network.connect({ network: "localhost" });

const [senderClient] = await viem.getWalletClients();

const deployedAddressesPath = "./ignition/deployments/chain-31337/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));
const erc20MockAddress = deployedAddresses["ERC20Mock#ERC20Mock"];

if (!erc20MockAddress) {
  throw new Error("ERC20Mock address not found for chain-31337");
}

const erc20Mock = await viem.getContractAt("ERC20Mock", erc20MockAddress);

const balance = await erc20Mock.read.balanceOf([senderClient.account.address]);
// const balance = await erc20Mock.balanceOf(senderClient.account.address);
console.dir(balance);
