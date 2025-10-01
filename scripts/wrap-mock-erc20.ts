import * as fs from "node:fs";
import { network } from "hardhat";
import { privateKeyToAccount } from "viem/accounts";

const { viem } = await network.connect({ network: "sepolia" });

const [senderClient] = await viem.getWalletClients();

const deployedAddressesPath = "./ignition/deployments/chain-11155111/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));
// const erc20MockAddress = deployedAddresses["ERC20Mock#ERC20Mock"];
const erc20MockAddress = "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238";

if (!erc20MockAddress) {
  throw new Error("ERC20Mock address not found for chain-11155111");
}
const erc20Mock = await viem.getContractAt("ERC20Mock", erc20MockAddress);

const metaERC20WrapperAddress = deployedAddresses["CurvyAggregator#MetaERC20Wrapper"];
if (!metaERC20WrapperAddress) {
  throw new Error("MetaERC20Wrapper address not found for chain-11155111");
}
const metaERC20Wrapper = await viem.getContractAt("MetaERC20Wrapper", metaERC20WrapperAddress);

const approval = await erc20Mock.write.approve([metaERC20WrapperAddress, 10n], { account: senderClient});
const deposit = await metaERC20Wrapper.write.deposit([erc20MockAddress, senderClient.address, 10n], {
  account: senderClient,
});
