import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import CurvyAggregatorAlphaModule from "./CurvyAggregatorAlpha";

const erc20Addresses = [
  "0xba5DdD1f9d7F570dc94a51479a000E3BCE967196",
  "0x912CE59144191C1204E64559FE8253a0e49E6548",
  "0xf97f4df75117a78c1a5a0dbb814af92458539fb4",
  "0x354A6dA3fcde098F8389cad84b0182725c6C91dE",
  "0xcb8b5CD20BdCaea9a010aC1F8d835824F5C87A04",
  "0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978",
  "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1",
  "0x6985884C4392D348587B19cb9eAAf157F13271cd",
  "0x13Ad51ed4F1B7e9Dc168d8a00cB3f4dDD85EfA60",
  "0x0c880f6761F1af8d9Aa9C466984b80DAb9a8c9e8",
  "0xd4d42F0b6DEF4CE0383636770eF773390d85c61A",
  "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9",
  "0x9623063377AD1B27544C965cCd7342f7EA7e88C7",
  "0xfa7f8980b0f1e64a2062791cc3b0871572f1f7f0",
  "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",
  "0x6491c05A82219b8D1479057361ff1654749b876b",
  "0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f",
];

export default buildModule("RegisterVaultTokens", (m) => {
  // Deploy aggregator and Vault
  const { curvyVault } = m.useModule(CurvyAggregatorAlphaModule);

  // biome-ignore lint/suspicious/noImplicitAnyLet: fuck off biome
  let previousRegistration;

  for (let i = 0; i < erc20Addresses.length; i++) {
    const address = erc20Addresses[i];

    // @ts-expect-error
    const after = [];
    if (previousRegistration) {
      after.push(previousRegistration);
    }

    previousRegistration = m.call(curvyVault, "registerToken", [address], {
      id: `RegisterVaultToken_${i}`,
      // @ts-expect-error
      after,
    });
  }

  return { curvyVault };
});
