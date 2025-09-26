import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import CurvyAggregator from "./CurvyAggregator";

export default buildModule("Devenv", (m) => {
  const { curvyAggregator, metaERC20Wrapper } =  m.useModule(CurvyAggregator);

  const multicall3 = m.contract("Multicall3");

  const erc20Mock = m.contract("ERC20Mock");

  // Account #0 in hardhat node
  m.call(erc20Mock, "mockMint", ["0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266", "100"]);

  // you can also send to an address directly
  m.send("wrapErc20Mock", erc20Mock, 0n, m.encodeFunctionCall("transfer", []), { from: m.getAccount(1) });

  m.send("approveErc20Mock", erc20Mock, 0n, m.encodeFunctionCall("approve", [metaERC20Wrapper]))

  const approval = await erc20Mock.write.approve([metaERC20WrapperAddress, 10n], { account: senderClient.account });
  const deposit = await metaERC20Wrapper.write.deposit([erc20MockAddress, senderClient.account.address, 10n], {
    account: senderClient.account,
  });

  m.send()
  m.call(erc20Mock, "transfer", []

  return { erc20Mock, multicall3 };
});
