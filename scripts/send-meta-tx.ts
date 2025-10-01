import fs from "node:fs";
import { network } from "hardhat";
import { concatHex, encodeAbiParameters, encodePacked, keccak256, parseAbiParameters, size, toBytes } from "viem";

const { viem } = await network.connect({ network: "localhost" });

const publicClient = await viem.getPublicClient();
const [senderClient, operatorClient, recipientClient, _operatorClient] = await viem.getWalletClients();

const deployedAddressesPath = "./ignition/deployments/chain-31337/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));

const metaERC20WrapperAddress = deployedAddresses["ERC20#MetaERC20Wrapper"];
if (!metaERC20WrapperAddress) {
  throw new Error("MetaERC20Wrapper address not found for chain-31337");
}
const metaERC20Wrapper = await viem.getContractAt("MetaERC20Wrapper", metaERC20WrapperAddress);
const erc20MockAddress = deployedAddresses["ERC20#ERC20Mock"];
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

console.log(erc20MockAddress);
console.log(metaERC20WrapperAddress);
const aaa = await metaERC20Wrapper.read.getIdAddress([2n]);
console.log(aaa);

const from = senderClient.account.address;
const to = recipientClient.account.address;
const id = await metaERC20Wrapper.read.getTokenID([erc20MockAddress]); // npr. 2n
const amount = 5n;
const isGasFee = false; // bez refund-a
const nonce = await metaERC20Wrapper.read.getNonce([from]);

// --- 1) _encMembers = abi.encode(META_TX_TYPEHASH, from, to, id, amount, isGasFee?1:0)
const META_TX_TYPEHASH = "0xce0b514b3931bdbe4d5d44e4f035afe7113767b7db71949271f6a62d9c60f558";
const encMembers = encodeAbiParameters(parseAbiParameters("bytes32, address, address, uint256, uint256, uint256"), [
  META_TX_TYPEHASH,
  from,
  to,
  id,
  amount,
  isGasFee ? 1n : 0n,
]);

// --- 2) signedData (tj. drugi element iz (bytes,bytes)) = abi.encode(bytes transferData)
//     ako ne šalješ custom transferData, neka bude prazan bytes
const transferData = "0x";
const signedData = encodeAbiParameters(parseAbiParameters("bytes"), [transferData]);

// --- 3) structHash i eip712Hash kao u kontraktu
const structHash = keccak256(encodePacked(["bytes", "uint256", "bytes32"], [encMembers, nonce, keccak256(signedData)]));

const DOMAIN_SEPARATOR_TYPEHASH = "0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749"; // iz LibEIP712
const domainSeparator = keccak256(
  encodeAbiParameters(parseAbiParameters("bytes32, address"), [DOMAIN_SEPARATOR_TYPEHASH, metaERC20WrapperAddress]),
);

// EIP-712 poruka (isto kao LibEIP712.hashEIP712Message)
const eip712Hash = keccak256(encodePacked(["bytes2", "bytes32", "bytes32"], ["0x1901", domainSeparator, structHash]));

// --- 4) POTPIS: EthSign (sigType=0x02) → potpisuješ RAW *32-bajtni* eip712Hash
const sig65 = await senderClient.signMessage({ message: { raw: toBytes(eip712Hash) } }); // r||s||v (65B)

// --- 5) Sastavi finalni sig: r||s||v||nonce(uint256)||sigType(0x02) → 98 bajtova
const noncePacked = encodePacked(["uint256"], [nonce]);
const sigWithNonceAndType = concatHex([sig65, noncePacked, "0x02"]);

// (opcionalno: proveri dužinu)
console.log("sig bytes:", size(sigWithNonceAndType)); // treba 98

// --- 6) finalni _data: abi.encode(bytes sig, bytes signedData)
const data = encodeAbiParameters(parseAbiParameters("bytes, bytes"), [sigWithNonceAndType, signedData]);

// --- 7) DEBUG: provera potpisa PRE nego što šalješ tx
const ok = await metaERC20Wrapper.read.isValidSignature([
  from,
  eip712Hash,
  encodePacked(["bytes", "uint256", "bytes"], [encMembers, nonce, signedData]),
  sigWithNonceAndType,
]);
console.log("isValidSignature?", ok); // očekuješ true

// --- 8) META TRANSFER (operator plaća gas)
const txHash = await metaERC20Wrapper.write.metaSafeTransferFrom([from, to, id, amount, isGasFee, data], {
  account: operatorClient.account,
});
console.log("tx:", txHash);

const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });

console.log(receipt);

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
