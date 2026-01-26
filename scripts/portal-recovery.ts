import * as fs from "node:fs";
import { Core } from "@0xcurvy/curvy-sdk";
import { network } from "hardhat";
import { privateKeyToAccount } from "viem/accounts";

const { viem } = await network.connect({ network: "sepolia" });
const [deployerClient] = await viem.getWalletClients();
const publicClient = await viem.getPublicClient();

console.log(`👷 Deployer Wallet: ${deployerClient.account.address}`);

const core = new Core();

// note data
const ownerHash = 104523775061865081978688333206914837947832712051815280022934306837594910208413n;
const tokenAddress = "0xabc";
const viewTag = "2a";
const ephemeralPublicKey = "216163113738129077026981082324476512393870475034151261972342073686655368504.17738778503081880329520898390562451499239148980806015804088882169172728886181";
const announcement = {
  createdAt: "2026-01-22T09:15:53.168Z",
  id: "49",
  networkFlavour: "evm",
  viewTag,
  ephemeralPublicKey,
} as const;

// address where user wants to recover their funds
const recoveryAddress = "0xabc";

// spending and viewing private keys of the user
const spendingPrivateKey = "";
const viewingPrivateKey = "";

const {
  spendingPrivKeys: [recoveryPrivateKey],
} = await core.scan(spendingPrivateKey, viewingPrivateKey, [announcement]);

const recoveryAccount = privateKeyToAccount(recoveryPrivateKey);

console.log(`Recovery wallet address: ${recoveryAccount.address}`);

const deployedAddressesPath = "./ignition/deployments/staging_ethereum-sepolia/deployed_addresses.json";
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));

const portalFactoryAddress = deployedAddresses["PortalFactoryAggregatorModule#PortalFactory"];

if (!portalFactoryAddress) {
  throw new Error("PortalFactory address not found.");
}

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