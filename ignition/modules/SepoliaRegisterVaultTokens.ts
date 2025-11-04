import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import CurvyAggregatorAlphaModule from "./CurvyAggregatorAlpha";

const erc20Addresses = ["0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238", "0x779877A7B0D9E8603169DdbD7836e478b4624789"];

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
