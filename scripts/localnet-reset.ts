import * as fs from "node:fs";
import { network } from "hardhat";
import { privateKeyToAccount } from "viem/accounts";

const { viem } = await network.connect({ network: "localhost" });

const deployedAddressesPath = "./ignition/deployments/chain-31337/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));
const curvyAggregatorAddress = deployedAddresses["CurvyAggregator#CurvyAggregator"];

if (!curvyAggregatorAddress) {
  throw new Error("Aggregator address not found for chain-31337");
}
const curvyAggregator = await viem.getContractAt("CurvyAggregator", curvyAggregatorAddress);

const operatorAccount = privateKeyToAccount("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");

await curvyAggregator.write.reset({ account: operatorAccount });
