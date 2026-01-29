import * as fs from "node:fs";
import { network } from "hardhat";

const { viem } = await network.connect({ network: "anvil" });

const deployedAddressesPath = "./ignition/deployments/staging_anvil/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));

const vaultAddress = deployedAddresses["CurvyVault#CurvyVaultV2"];
if (!vaultAddress) {
  throw new Error("CurvyVault address not found for anvil");
}
const vault = await viem.getContractAt("CurvyVaultV2", vaultAddress);

const balance = await vault.read.balanceOf(["0x59b670e9fA9D0A427751Af201D676719a970857b", 1n]);

console.log(balance);
