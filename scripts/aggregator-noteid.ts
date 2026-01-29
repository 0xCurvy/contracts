import * as fs from "node:fs";
import { network } from "hardhat";

const { viem } = await network.connect({ network: "anvil" });

const deployedAddressesPath = "./ignition/deployments/staging_anvil/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));
const curvyAggregatorAddress = deployedAddresses["CurvyAggregatorAlpha#CurvyAggregatorAlphaV2"];

if (!curvyAggregatorAddress) {
  throw new Error("Aggregator address not found for anvil");
}
const curvyAggregator = await viem.getContractAt("CurvyAggregatorAlphaV2", curvyAggregatorAddress);

const noteid = await curvyAggregator.read.noteInQueue([
  14967077268631546162044198053248993673186354912497893587694799228971941136645n,
]);

console.log(`Note ${noteid} in queue`, noteid);
