import fs from "node:fs";
import { network } from "hardhat";
import { parseEventLogs } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { expect, test } from "vitest";
import { fullyQualifiedName } from "../artifact-registry.mjs";

/**
 * Automatic shielding against the V2 stack.
 *
 * Flow: predict the portal address for an owner hash, send tokens to it, then have the
 * factory deploy the portal, which auto-shields the balance into a pending note.
 *
 * Requires a local deployment:
 *
 *   pnpm deploy:local     # writes ignition/deployments/local_anvil + cache/anvil_state.json
 *   pnpm start:anvil      # reloads that state
 *
 * Both are gitignored, so a fresh checkout has neither. NOTE: this test needs a CLEAN
 * chain each run — the portal is a deterministic CREATE2 clone, so a second run against
 * the same anvil reverts with `FailedDeployment()`. Restart `start:anvil` between runs.
 */
test("automatic-shielding", async () => {
  const ownerHash = 702705117071108858750548073842146797693190729490869702449519502701872077655n;
  const token = 2n;

  const { viem } = await network.connect({ network: "anvil" });

  const deployedAddressesPath = "./ignition/deployments/local_anvil/deployed_addresses.json";
  const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));

  const address = (key: string): `0x${string}` => {
    const value = deployedAddresses[key];
    if (!value) throw new Error(`${key} not found in ${deployedAddressesPath}`);
    return value;
  };

  // `PortalFactory` and `Portal` are ambiguous short names across the v1/v2 trees, so
  // Hardhat types them as `never`. The fully qualified name from the shared registry
  // pins the V2 artifact.
  const curvyVault = await viem.getContractAt("CurvyVaultV2", address("CurvyVault#ERC1967Proxy"));
  const portalFactory = await viem.getContractAt(
    fullyQualifiedName("PortalFactory"),
    address("PortalFactory#PortalFactory"),
  );
  const curvyAggregatorAlpha = await viem.getContractAt(
    "CurvyAggregatorAlphaV2",
    address("CurvyAggregator#ERC1967Proxy"),
  );
  const erc20Mock = await viem.getContractAt("ERC20Mock", address("Devenv#ERC20Mock"));

  const tokenIdOfErc20Mock = await curvyVault.read.getTokenId([erc20Mock.address]);
  expect(tokenIdOfErc20Mock).toBe(token);

  const tokenAddress = await curvyVault.read.getTokenAddress([token]);
  expect(tokenAddress).toBe(erc20Mock.address);

  // User's wallet, randomly generated — account 0x0eeCE19240e3A8826d92da5f4D31581a1DC97779
  const user = privateKeyToAccount("0x49593edf99c94e11b7e1e6f98387af4b5bb996ee76723f0ab5a658ba643d1058");
  const userClient = await viem.getWalletClient(user.address);
  const publicClient = await viem.getPublicClient();

  // V2 charges per-token gas fees on top of the percentage deposit fee, and `autoShield`
  // underflows if the shielded amount cannot cover them — so size the amount off the
  // live fees rather than hardcoding it.
  const depositFee = await curvyVault.read.depositFee();
  const gasFees = await curvyVault.read.perTokenGasFees([token]);
  const totalGasFees = gasFees.portalDeployment + gasFees.pendingNoteCommitment;
  const amount = totalGasFees * 4n;

  // V2 portals require a non-zero recovery address (`Portal.initialize` reverts with
  // InvalidRecoveryAddress otherwise) and it is part of the CREATE2 salt, so the same
  // value must be used to predict the address and to deploy.
  const recovery = user.address;
  const portalAddress = await portalFactory.read.getEntryPortalAddress([ownerHash, recovery]);

  const { request } = await publicClient.simulateContract({
    account: user,
    address: erc20Mock.address,
    abi: erc20Mock.abi,
    functionName: "transfer",
    args: [portalAddress, amount],
  });
  const receipt = await publicClient.waitForTransactionReceipt({ hash: await userClient.writeContract(request) });
  expect(receipt.status).toBe("success");

  // `deployShieldPortal` is OPERATOR_ROLE-gated; the factory grants it to the deployer
  // (anvil account 0), which is the default wallet client here.
  const deployHash = await portalFactory.write.deployShieldPortal([
    { ownerHash, token, amount, ephemeralKey: [0n, 0n], viewTag: 0 },
    recovery,
  ]);
  const deployReceipt = await publicClient.waitForTransactionReceipt({ hash: deployHash });
  expect(deployReceipt.status).toBe("success");

  // Both the percentage deposit fee and the per-token gas fees come off the deposit; the
  // remainder is what the aggregator holds in the vault and what is bound into the note.
  const netAmount = amount - (amount * BigInt(depositFee)) / 10_000n - totalGasFees;

  expect(await curvyVault.read.balanceOf([curvyAggregatorAlpha.address, tokenIdOfErc20Mock])).toBe(netAmount);

  // The note id is PoseidonT4(ownerHash, netAmount, token) — read it off the event the
  // aggregator emitted rather than recomputing the hash here.
  const [pendingNotes] = parseEventLogs({
    abi: curvyAggregatorAlpha.abi,
    eventName: "PendingNotes",
    logs: deployReceipt.logs,
  });
  expect(pendingNotes).toBeDefined();
  expect(pendingNotes.args.amounts[0]).toBe(netAmount);
  expect(pendingNotes.args.tokens[0]).toBe(token);

  // NoteStatus { UNKNOWN, PENDING, INCLUDED } — auto-shielding leaves it PENDING until
  // a batch commitment includes it.
  const noteId = pendingNotes.args.noteIds[0];
  expect(await curvyAggregatorAlpha.read.noteStatus([noteId])).toBe(1);
});
