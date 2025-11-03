import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { network } from "hardhat";
import { privateKeyToAccount } from "viem/accounts";
import { test } from "vitest";

const harness = buildModule("CurvyVault", (m) => {
  const implementation = m.contract("CurvyVaultV1ValidateSignatureHarness", [], { id: "CurvyVaultV1Implementation" });

  const owner = m.getAccount(0);

  const proxy = m.contract("ERC1967Proxy", [
    implementation,
    m.encodeFunctionCall(implementation, "initialize", [owner]),
  ]);

  const curvyVault = m.contractAt("CurvyVaultV1ValidateSignatureHarness", proxy);

  return { implementation, proxy, curvyVault };
});

test("eip-712 signing", async () => {
  const { ignition, viem } = await network.connect();

  const { curvyVault } = await ignition.deploy(harness);

  const privateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
  const account = privateKeyToAccount(privateKey);

  const name = "Curvy Privacy Vault";
  const version = "1.0";
  const verifyingContract = curvyVault.address;

  const client = await viem.getPublicClient();
  const chainId = await client.getChainId();

  const nonce = 0n;
  const from = account.address;
  const to = "0x0b306bf915c4d645ff596e518faf3f9669b97016";
  const tokenId = 1n;
  const amount = 998999905426735528144n;
  const gasFee = 0n;
  const metaTransactionType = 1;

  const signature = await account.signTypedData({
    domain: {
      name,
      version,
      chainId,
      verifyingContract,
    },
    primaryType: "CurvyMetaTransaction",
    types: {
      CurvyMetaTransaction: [
        { name: "nonce", type: "uint256" },
        { name: "from", type: "address" },
        { name: "to", type: "address" },
        { name: "tokenId", type: "uint256" },
        { name: "amount", type: "uint256" },
        { name: "gasFee", type: "uint256" },
        { name: "metaTransactionType", type: "uint8" },
      ],
    },
    message: {
      nonce,
      from,
      to,
      tokenId,
      amount,
      gasFee,
      metaTransactionType,
    },
  });

  await curvyVault.write._validateSignature_Harness([
    { from, to, tokenId, amount, gasFee, metaTransactionType },
    signature,
  ]);
}, 5000000);
