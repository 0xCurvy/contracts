import * as fs from "node:fs";
import { network } from "hardhat";

const { viem } = await network.connect({ network: "anvil" });

const deployedAddressesPath = "./ignition/deployments/staging_anvil/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));

const vaultAddress = deployedAddresses["CurvyVault#CurvyVaultV1"];
if (!vaultAddress) {
  throw new Error("Vault address not found for anvil_staging");
}
const vault = await viem.getContractAt("CurvyVaultV3", vaultAddress);

const tokenAddress = await vault.read.getTokenAddress([1]);
console.log(tokenAddress);
