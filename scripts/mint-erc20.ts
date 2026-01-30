import * as fs from "node:fs";
import { network } from "hardhat";

const { viem } = await network.connect({ network: "anvil" });

const deployedAddressesPath = "./ignition/deployments/staging_anvil/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));

const erc20MockAddress = deployedAddresses["Devenv#ERC20Mock"];
if (!erc20MockAddress) {
  throw new Error("MetaERC20Wrapper address not found for anvil");
}
const erc20Mock = await viem.getContractAt("ERC20Mock", erc20MockAddress);

erc20Mock.write.mockMint(["0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266", 5000n * 10n ** 18n]);
