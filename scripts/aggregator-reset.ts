import * as fs from "node:fs";
import { network } from "hardhat";

const { viem } = await network.connect({ network: "sepolia" });

const [senderClient] = await viem.getWalletClients();

const deployedAddressesPath = "./ignition/deployments/staging_ethereum-sepolia/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));
const curvyAggregatorAddress = deployedAddresses["CurvyAggregatorAlpha#ERC1967Proxy"];

if (!curvyAggregatorAddress) {
  throw new Error("Aggregator address not found for staging_ethereum-sepolia");
}
const curvyAggregator = await viem.getContractAt("CurvyAggregatorAlphaV3", curvyAggregatorAddress);

const reset = await curvyAggregator.write.reset([0n, 0n], { account: senderClient.account});

console.log("Reset is done in transaction: ", reset);
