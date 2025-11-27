import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import CurvyAggregatorAlphaModule from "./CurvyAggregatorAlpha";

export default buildModule("AutomaticShielding", (m) => {
  const sender = m.getAccount(1);
  const ownerHash = "0x123";
  const token = "1";
  const amount = "100";

  const noteId = "0x23";
  const salt = "0x1230000000000000000000000000000012300000000000000000000000000000";

  //  Resolve stealth address
  const sa = "0x0eeCE19240e3A8826d92da5f4D31581a1DC97779";

  const walletFactory = m.contract("WalletFactory");

  const deployTx = m.call(walletFactory, "deploy", [noteId, sa, salt], { id: "DeployWalletTx" });

  const predictedAddress = m.staticCall(walletFactory, "getContractAddress", [noteId, sa, salt]);

  const walletDummy = m.contractAt("WalletDummy", predictedAddress, { id: "DummyWalletInstance", after: [deployTx] });

  const { curvyAggregatorAlphaV2 } = m.useModule(CurvyAggregatorAlphaModule);

  const signature = "0xabc";

  m.call(curvyAggregatorAlphaV2, "depositNote", [sender, { ownerHash, token, amount }, signature], {
    id: "DepositToAggregator",
  });

  return { walletDummy };
});
