import * as fs from "node:fs";
import { network } from "hardhat";

const { viem } = await network.connect({ network: "anvil" });

const deployedAddressesPath = "./ignition/deployments/chain-31337/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));

const vaultAddress = deployedAddresses["CurvyVault#CurvyVaultV1"];
if (!vaultAddress) {
  throw new Error("MetaERC20Wrapper address not found for chain-31337");
}
const vault = await viem.getContractAt("CurvyVaultV1", vaultAddress);

const nonce = await vault.read.getNonce(["0xE1c608bE16cA3aEe2DBCDDcB5Abd8A029ab78F54"]);

console.dir(nonce);
