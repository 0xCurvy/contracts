import { Address, createPublicClient, defineChain, getContract, http } from "viem";
import CurvyAggregatorArtifacts from './artifacts/contracts/aggregator/CurvyAggregator.sol/CurvyAggregator.json';
import deployedAddresses from './ignition/deployments/chain-31337/deployed_addresses.json';

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

    const publicClient = createPublicClient({
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