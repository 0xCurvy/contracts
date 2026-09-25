import * as fs from "node:fs";
import { network } from "hardhat";

const { viem } = await network.connect({ network: "anvil" });

const deployedAddressesPath = "./ignition/deployments/local_anvil/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));

const vaultAddress = deployedAddresses["CurvyVault#ERC1967Proxy"];
if (!vaultAddress) {
  throw new Error("Vault address not found for anvil_staging");
}
const vault = await viem.getContractAt("CurvyVaultV1", vaultAddress);

const tokenAddress = await vault.read.getTokenAddress([1n]);
console.log(tokenAddress);
