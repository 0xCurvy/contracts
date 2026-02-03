import { createPublicClient, http } from "viem";
import { anvil } from "viem/chains";
import { test } from "vitest";

const client = createPublicClient({
  chain: {
    ...anvil,
    contracts: {
      ensRegistry: { address: "0xa513E6E4b8f2a923D98304ec87F64353C4D5C853" },
      ensUniversalResolver: { address: "0x68B1D87F95878fE05B998F19b66F4baba5De1aed" },
    },
  },
  transport: http(),
});

test("ens-resolve", async () => {
  // This function internally handles the OffchainLookup revert and calls your backend
  const address = await client.getEnsAddress({
    name: "devenv1.local-curvy.name",
  });

  console.log(`Resolved address from offchain backend: ${address}`);
});
