import { createPublicClient, http } from 'viem';
import { anvil } from 'viem/chains';
import { test } from 'vitest';

const client = createPublicClient({
    chain: {
        ...anvil,
        contracts: {
            ensRegistry: { address: '0x0165878A594ca255338adfa4d48449f69242Eb8F' },
            universalResolver: { address: '0x0165878A594ca255338adfa4d48449f69242Eb8F' },
        }
    },
    transport: http(),
});

test("ens-resolve", async () => {
    // This function internally handles the OffchainLookup revert and calls your backend
    const address = await client.getEnsAddress({
        name: 'local-curvy.name',
    });

    console.log(`Resolved address from offchain backend: ${address}`);
});