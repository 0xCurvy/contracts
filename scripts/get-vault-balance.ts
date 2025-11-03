import * as fs from "node:fs";
import { network } from "hardhat";

const { viem } = await network.connect({ network: "localhost" });

const deployedAddressesPath = "./ignition/deployments/chain-31337/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));

const vaultAddress = deployedAddresses["CurvyVault#CurvyVaultV1"];
if (!vaultAddress) {
  throw new Error("MetaERC20Wrapper address not found for chain-31337");
}
const vault = await viem.getContractAt("CurvyVaultV1", vaultAddress);

const balance = await vault.read.balanceOf(["0x9C6477175e15964f6Eb133da2b6d86fBe513de4a", 2n]);

console.dir(balance);
