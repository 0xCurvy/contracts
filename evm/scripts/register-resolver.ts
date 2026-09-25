import { network } from "hardhat";
import { namehash } from "viem";

/**
 * Points an ENS name's resolver at a deployed `OffchainResolver` (the ERC-3668
 * CCIP-Read entry point). Run AFTER deploying the resolver with
 * `ignition/modules/building-blocks/OffchainResolver.ts`.
 *
 * Ported from the former `packages/ens-resolver/contracts` Hardhat 2 / ethers
 * script to this package's Hardhat 3 + viem toolchain.
 *
 * Required env:
 *   CURVY_NETWORK     hardhat network to connect to (e.g. `sepolia`, `ethereum`)
 *   CURVY_ENS_DOMAIN  the ENS name to configure (e.g. `curvy.eth`)
 *   OFFCHAIN_RESOLVER deployed OffchainResolver address
 *   ENS_REGISTRY      ENS registry address on the target chain
 *
 *   hardhat run scripts/register-resolver.ts
 */
const networkName = process.env.CURVY_NETWORK;
if (!networkName) {
  throw new Error("CURVY_NETWORK env var must be set (the hardhat network to connect to, e.g. sepolia)");
}

const domain = process.env.CURVY_ENS_DOMAIN;
if (!domain) {
  throw new Error("CURVY_ENS_DOMAIN not set in the environment");
}

const resolverAddress = process.env.OFFCHAIN_RESOLVER as `0x${string}` | undefined;
if (!resolverAddress) {
  throw new Error("OFFCHAIN_RESOLVER (deployed resolver address) not set in the environment");
}

const ensRegistryAddress = process.env.ENS_REGISTRY as `0x${string}` | undefined;
if (!ensRegistryAddress) {
  throw new Error("ENS_REGISTRY not set in the environment");
}

// Minimal ENS registry ABI.
const ensRegistryAbi = [
  {
    type: "function",
    name: "setResolver",
    stateMutability: "nonpayable",
    inputs: [
      { name: "node", type: "bytes32" },
      { name: "resolver", type: "address" },
    ],
    outputs: [],
  },
  {
    type: "function",
    name: "resolver",
    stateMutability: "view",
    inputs: [{ name: "node", type: "bytes32" }],
    outputs: [{ name: "", type: "address" }],
  },
] as const;

const { viem } = await network.connect({ network: networkName });
const [walletClient] = await viem.getWalletClients();
const publicClient = await viem.getPublicClient();

const node = namehash(domain);

const hash = await walletClient.writeContract({
  address: ensRegistryAddress,
  abi: ensRegistryAbi,
  functionName: "setResolver",
  args: [node, resolverAddress],
});
console.log(`setResolver tx sent: ${hash}`);

await publicClient.waitForTransactionReceipt({ hash });
console.log(`Resolver for ${domain} (${node}) set to ${resolverAddress} on ${networkName}`);
