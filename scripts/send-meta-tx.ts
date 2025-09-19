import fs from "node:fs";
import { network } from "hardhat";

const { viem } = await network.connect({ network: "localhost" });

const publicClient = await viem.getPublicClient();
const [senderClient, operatorClient, recipientClient] = await viem.getWalletClients();

const deployedAddressesPath = "./ignition/deployments/chain-31337/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));

const metaERC20WrapperAddress = deployedAddresses["MetaERC20Wrapper#MetaERC20Wrapper"];
if (!metaERC20WrapperAddress) {
  throw new Error("MetaERC20Wrapper address not found for chain-31337");
}
const metaERC20Wrapper = await viem.getContractAt("MetaERC20Wrapper", metaERC20WrapperAddress);

const erc20MockAddress = deployedAddresses["ERC20Mock#ERC20Mock"];
if (!erc20MockAddress) {
  throw new Error("ERC20Mock address not found for chain-31337");
}
const erc20Mock = await viem.getContractAt("ERC20Mock", erc20MockAddress);

console.log("\n***NATIVE BALANCES***\n");
console.log("SENDER:", await publicClient.getBalance({ address: senderClient.account.address }));
console.log("OPERATOR:", await publicClient.getBalance({ address: operatorClient.account.address }));
console.log("RECEIVER:", await publicClient.getBalance({ address: recipientClient.account.address }));

console.log("\n***ERC20 BALANCES***\n");
console.log("SENDER:", await erc20Mock.read.balanceOf([senderClient.account.address]));
console.log("OPERATOR:", await erc20Mock.read.balanceOf([operatorClient.account.address]));
console.log("RECIPIENT:", await erc20Mock.read.balanceOf([recipientClient.account.address]));

// await erc20Mock.write.approve([metaERC20WrapperAddress, 10n], { account: senderClient.account });
// await metaERC20Wrapper.write.deposit([erc20MockAddress, senderClient.account.address, 10n], {
//   account: senderClient.account,
// });

console.log("\n***ERC20Wrapped BALANCES***\n");
console.log("SENDER:", await metaERC20Wrapper.read.balanceOf([senderClient.account.address, 2n]));
console.log("OPERATOR:", await metaERC20Wrapper.read.balanceOf([operatorClient.account.address, 2n]));
console.log("RECIPIENT:", await metaERC20Wrapper.read.balanceOf([recipientClient.account.address, 2n]));

const signature = await senderClient.signTypedData({
  domain: {
    name: "Wrap Test",
    version: "1",
    chainId: 31337,
    verifyingContract: metaERC20WrapperAddress,
  },
  types: {
    Test: [
      { name: "META_TX_TYPEHASH", type: "bytes32" },
      { name: "from", type: "address" },
      { name: "to", type: "address" },
      { name: "id", type: "uint256" },
      { name: "amount", type: "uint256" },
      { name: "isGasFee", type: "uint256" },
      { name: "nonce", type: "uint256" },
    ],
  } as const,
  primaryType: "Test",
  message: {
    META_TX_TYPEHASH: "0xce0b514b3931bdbe4d5d44e4f035afe7113767b7db71949271f6a62d9c60f558",
    from: senderClient.account.address,
    to: recipientClient.account.address,
    id: 2n,
    amount: 5n,
    isGasFee: 1n,
    nonce: await metaERC20Wrapper.read.getNonce([senderClient.account.address]),
  },
});

const txHash = await metaERC20Wrapper.write.metaSafeTransferFrom(
  [senderClient.account.address, recipientClient.account.address, 2n, 5n, true, signature],
  { account: operatorClient.account },
);

console.log(`Transaction sent: ${txHash}`);

console.log("\n***NATIVE BALANCES***\n");
console.log("SENDER:", await publicClient.getBalance({ address: senderClient.account.address }));
console.log("OPERATOR:", await publicClient.getBalance({ address: operatorClient.account.address }));
console.log("RECEIVER:", await publicClient.getBalance({ address: recipientClient.account.address }));

console.log("\n***ERC20 BALANCES***\n");
console.log("SENDER:", await erc20Mock.read.balanceOf([senderClient.account.address]));
console.log("OPERATOR:", await erc20Mock.read.balanceOf([operatorClient.account.address]));
console.log("RECIPIENT:", await erc20Mock.read.balanceOf([recipientClient.account.address]));

console.log("\n***ERC20Wrapped BALANCES***\n");
console.log("SENDER:", await metaERC20Wrapper.read.balanceOf([senderClient.account.address, 2n]));
console.log("OPERATOR:", await metaERC20Wrapper.read.balanceOf([operatorClient.account.address, 2n]));
console.log("RECIPIENT:", await metaERC20Wrapper.read.balanceOf([recipientClient.account.address, 2n]));
