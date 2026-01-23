import * as fs from "node:fs";
import { Core } from "@0xcurvy/curvy-sdk";
import { network } from "hardhat";
import { privateKeyToAccount } from "viem/accounts";

const { viem } = await network.connect({ network: "sepolia" });
const [deployerClient] = await viem.getWalletClients();
const publicClient = await viem.getPublicClient();

console.log(`👷 Deployer Wallet: ${deployerClient.account.address}`);

const core = new Core();

const announcement = {
  createdAt: "2026-01-22T09:15:53.168Z",
  id: "49",
  networkFlavour: "evm",
  viewTag: "2b",
  ephemeralPublicKey:
    "12694814128352825173555891916474688948022902810048283398122577572297648545302.769867253832128338353427508361950705748312918666179012235061862770337441780",
} as const;

// spending and viewing private keys of the user
const spendingPrivateKey = "";
const viewingPrivateKey = "";

const {
  spendingPrivKeys: [recoveryPrivateKey],
} = await core.scan(spendingPrivateKey, viewingPrivateKey, [announcement]);

const recoveryAccount = privateKeyToAccount(recoveryPrivateKey);

const deployedAddressesPath = "./ignition/deployments/staging_ethereum-sepolia/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));

const portalFactoryAddress = deployedAddresses["PortalFactoryAggregatorModule#PortalFactory"];
// address of token that user wants to recover
const tokenAddress = "0x08210F9170F89Ab7658F0B5E3fF39b0E03C594D4";

if (!portalFactoryAddress) {
  throw new Error("PortalFactory address not found.");
}

const ownerHash = 4858610214764074763546445921752291276456790862179504486794658106036719941752n;
// address where user wants to recover their funds
const recoveryAddress = "0xabc123";

const portalFactory = await viem.getContractAt("PortalFactory", portalFactoryAddress);

console.log("Calculating expected Portal address...");
const expectedPortalAddress = await portalFactory.read.getPortalAddress([ownerHash, recoveryAccount.address]);
console.log(`Target Portal Address: ${expectedPortalAddress}`);

const bytecode = await publicClient.getCode({ address: expectedPortalAddress });
const isDeployed = bytecode && bytecode !== "0x";

if (!isDeployed) {
  console.log("⚠️ Portal code NOT found at this address.");
  console.log("🚀 Deploying Portal now to enable recovery...");

  const dummyNote = {
    ownerHash: ownerHash,
    token: 0n,
    amount: 0n,
  };

  const deployHash = await portalFactory.write.deployAndShield([dummyNote, recoveryAccount.address], {
    account: deployerClient.account,
  });

  console.log("Deploy transaction sent:", deployHash);
  console.log("Waiting for confirmation...");

  const receipt = await publicClient.waitForTransactionReceipt({ hash: deployHash });

  if (receipt.status !== "success") {
    throw new Error("Portal deployment failed!");
  }
  console.log("✅ Portal successfully deployed!");
} else {
  console.log("✅ Portal is already deployed.");
}

console.log("Initiating recovery...");

const portal = await viem.getContractAt("Portal", expectedPortalAddress);
const recoverTx = await portal.write.recover([tokenAddress, recoveryAddress], { account: recoveryAccount });
console.log("💸 Recovery transaction sent:", recoverTx);