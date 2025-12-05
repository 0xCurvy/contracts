import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("AutomaticShieldingModule", (m) => {
  // Deploy aggregator and Vault
  const aggregatorAddress = m.getParameter("aggregatorAddress", "0x0000000000000000000000000000000000000000");
  const vaultAddress = m.getParameter("vaultAddress", "0x0000000000000000000000000000000000000000");
  const lifiDiamondAddress = m.getParameter("lifiDiamondAddress", "0x0000000000000000000000000000000000000000");

  const noteDeployerFactory = m.contract(
    "NoteDeployerFactory",
    [aggregatorAddress, vaultAddress, lifiDiamondAddress],
    {},
  );

  return { noteDeployerFactory };
});
