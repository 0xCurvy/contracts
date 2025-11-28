import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("AutomaticShielding", (m) => {
  const ownerHash = "0x123";
  const token = "1";
  const amount = "100";

  const salt = "0x1230000000000000000000000000000012300000000000000000000000000000";

  //  Resolve stealth address
  const sa = "0x0eeCE19240e3A8826d92da5f4D31581a1DC97779";

  const walletFactory = m.contract("WalletFactory");

  const deployTx = m.call(walletFactory, "deploy", [{ ownerHash, token, amount }, salt], { id: "DeployWalletTx" });

  const predictedAddress = m.staticCall(walletFactory, "getContractAddress", [{ ownerHash, token, amount }, salt]);

  const walletDummy = m.contractAt("WalletDummy", predictedAddress, { id: "DummyWalletInstance", after: [deployTx] });

  return { walletDummy };
});
