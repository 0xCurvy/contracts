import fs from "node:fs";
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { labelhash, namehash } from "viem";
import CurvyAggregatorAlphaModule from "./CurvyAggregatorAlpha";

const DEPOSIT_AMOUNT = 1000n * 10n ** 18n;

export default buildModule("Devenv", (m) => {
  const deployer = m.getAccount(0);

  // Deploy aggregator, vault and portal factory
  const { curvyVault, curvyAggregatorAlpha } = m.useModule(CurvyAggregatorAlphaModule);

  const portalFactory = m.contract("PortalFactory", [deployer], { id: "PortalFactory", after: [curvyVault] });

  m.call(
    portalFactory,
    "updateConfig",
    [curvyVault.address, curvyAggregatorAlpha.address, "0x0000000000000000000000000000000000000000"],
    { after: [portalFactory] },
  );

  // Deploy multicall
  const multicall3 = m.contract("Multicall3");

  // Deploy mock erc20
  const erc20Mock = m.contract("ERC20Mock");

  // ENS Setup
  const GATEWAY_URL = "http://localhost:4000/gateway/testnet/{sender}/{data}.json";
  const ROOT_NODE = "0x0000000000000000000000000000000000000000000000000000000000000000";
  // Deploy Registry
  const registry = m.contract("LocalENSRegistry");

  // Deploy SimpleOffchainResolver
  // Arguments: [url, signer_address]
  const offchain = m.contract("SimpleOffchainResolver", [GATEWAY_URL, deployer]);

  // Deploy Universal Resolver
  // Arguments: [registry_address, wildcard_node_hash]
  const localCurvyNode = namehash("local-curvy.name");

  const universal = m.contract("LocalUniversalResolver", [registry, localCurvyNode], {
    id: "LocalUniversalResolver",
  });

  // Configure TLD: .name
  // registry.setSubnodeOwner(ROOT_NODE, labelhash("name"), deployer)
  const setupTld = m.call(registry, "setSubnodeOwner", [ROOT_NODE, labelhash("name"), deployer], {
    id: "setup_tld",
  });

  // Configure Domain: local-curvy.name
  // registry.setSubnodeRecord(nameNode, labelhash("local-curvy"), deployer, offchainAddress, ttl)
  const nameNode = namehash("name");

  m.call(
    registry,
    "setSubnodeRecord",
    [
      nameNode,
      labelhash("local-curvy"),
      deployer,
      offchain,
      0, // TTL
    ],
    {
      id: "setup_subnode_record",
      after: [setupTld], // Ensure TLD is set before setting subdomain
    },
  );

  const addresses = JSON.parse(fs.readFileSync("../devenv/addresses.json", "utf-8"));
  for (const userAddresses of addresses) {
    // First address gets ETH
    m.send(`Send_ETH_${userAddresses[0]}`, userAddresses[0], DEPOSIT_AMOUNT, undefined, { from: deployer });

    // Second just gets mock ERC20
    m.call(erc20Mock, "mockMint", [userAddresses[1], DEPOSIT_AMOUNT], { id: `Mint_ERC20_${userAddresses[1]}` });

    // Third gets nothing
  }

  m.call(curvyVault, "registerToken", [erc20Mock], { id: "Register_MockERC20" });

  const userAddressForAutomaticShielding = "0x0eeCE19240e3A8826d92da5f4D31581a1DC97779";

  m.send(`Send_ETH_${userAddressForAutomaticShielding}`, userAddressForAutomaticShielding, DEPOSIT_AMOUNT, undefined, {
    from: deployer,
  });
  m.call(erc20Mock, "mockMint", [userAddressForAutomaticShielding, DEPOSIT_AMOUNT], {
    id: `Mint_ERC20_${userAddressForAutomaticShielding}`,
  });

  return { erc20Mock, multicall3, curvyVault, portalFactory, universal, registry, offchain };
});
