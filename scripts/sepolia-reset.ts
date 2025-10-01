import * as fs from "node:fs";
import { network } from "hardhat";

const { viem } = await network.connect({ network: "sepolia" });

const [senderClient] = await viem.getWalletClients();

const deployedAddressesPath = "./ignition/deployments/chain-11155111/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));
const curvyAggregatorAddress = deployedAddresses["CurvyAggregator#CurvyAggregator"];

if (!curvyAggregatorAddress) {
  throw new Error("Aggregator address not found for chain-11155111");
}
const curvyAggregator = await viem.getContractAt("CurvyAggregator", curvyAggregatorAddress);

const reset = await curvyAggregator.write.reset({ account: senderClient.account});
