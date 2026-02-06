import { createPublicClient, http } from "viem";
import { anvil } from "viem/chains";
import { test } from "vitest";

const client = createPublicClient({
  chain: {
    ...anvil,
    contracts: {
      ensRegistry: { address: "0xa513E6E4b8f2a923D98304ec87F64353C4D5C853" },
      ensUniversalResolver: { address: "0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE" },
    },
  },
  transport: http(),
});

test("ens-resolve", async () => {
  const address = await client.getEnsAddress({
    name: "devenv1.local-curvy.name",
    coinType: 9004n,
    // coinType:toCoinType(42161)
  });

  console.log(`Resolved address from offchain backend: ${address}`);
});
