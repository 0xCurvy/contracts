import * as fs from "node:fs";
import { network } from "hardhat";

const { viem } = await network.connect({ network: "localhost" });

const [senderClient] = await viem.getWalletClients();

const deployedAddressesPath = "./ignition/deployments/chain-31337/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));
const erc20MockAddress = deployedAddresses["ERC20Mock#ERC20Mock"];

if (!erc20MockAddress) {
  throw new Error("ERC20Mock address not found for chain-31337");
}
const erc20Mock = await viem.getContractAt("ERC20Mock", erc20MockAddress);

const metaERC20WrapperAddress = deployedAddresses["MetaERC20Wrapper#MetaERC20Wrapper"];
if (!metaERC20WrapperAddress) {
  throw new Error("MetaERC20Wrapper address not found for chain-31337");
}
const metaERC20Wrapper = await viem.getContractAt("MetaERC20Wrapper", metaERC20WrapperAddress);

const approval = await erc20Mock.write.approve([metaERC20WrapperAddress, 10n], { account: senderClient.account });
const deposit = await metaERC20Wrapper.write.deposit([erc20MockAddress, senderClient.account.address, 10n], {
  account: senderClient.account,
});
