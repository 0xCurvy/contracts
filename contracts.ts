import { Address, createWalletClient, defineChain, getContract, http } from "viem";
import CurvyAggregatorArtifacts from './artifacts/contracts/aggregator/CurvyAggregator.sol/CurvyAggregator.json';
import deployedAddresses from './ignition/deployments/chain-31337/deployed_addresses.json';
import { privateKeyToAccount } from "viem/accounts"; // Convert private key to account

export const getContracts = (rpcUrl: string = 'http://localhost:8545', networkName: string = 'localhost') => {

    const chain = defineChain({
        id: Number(31337),
        name: networkName,
        rpcUrls: {
            default: {
                http: [rpcUrl],
            },
        },
        nativeCurrency: {
            name: 'ETH',
            symbol: 'ETH',
            decimals: 18,
        },
    });

    const account = privateKeyToAccount("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");

    const publicClient = createWalletClient({
        account,
        chain,
        transport: http(rpcUrl),
    });

    const curvyAggregator = getContract({
        abi: CurvyAggregatorArtifacts.abi,
        address: deployedAddresses["CurvyAggregator#CurvyAggregator"] as Address,
        client: publicClient,
    });

    return {
        curvyAggregator,
    }
}