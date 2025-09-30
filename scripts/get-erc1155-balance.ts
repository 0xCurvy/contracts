import * as fs from "node:fs";
import { network } from "hardhat";

const { viem } = await network.connect({ network: "localhost" });

const [senderClient] = await viem.getWalletClients();

const deployedAddressesPath = "./ignition/deployments/chain-31337/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));

const metaERC20WrapperAddress = deployedAddresses["CurvyAggregator#MetaERC20Wrapper"];
if (!metaERC20WrapperAddress) {
  throw new Error("MetaERC20Wrapper address not found for chain-31337");
}
const metaERC20Wrapper = await viem.getContractAt("MetaERC20Wrapper", metaERC20WrapperAddress);

const balance = await metaERC20Wrapper.read.balanceOf([senderClient.account.address, 2n]);

console.dir(balance);
