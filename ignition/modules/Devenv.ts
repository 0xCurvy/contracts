import fs from "node:fs";
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { keccak256, toHex, stringToBytes, namehash } from "viem";
import CurvyAggregatorAlphaModule from "./CurvyAggregatorAlpha";
import PortalFactoryModule from "./PortalFactory";

const DEPOSIT_AMOUNT = 1000n * 10n ** 18n;

export default buildModule("Devenv", (m) => {
  // Deploy aggregator, vault and portal factory
  const { curvyVault } = m.useModule(CurvyAggregatorAlphaModule);
  const { portalFactory } = m.useModule(PortalFactoryModule);

  // Deploy multicall
  const multicall3 = m.contract("Multicall3");

  // Deploy mock erc20
  const erc20Mock = m.contract("ERC20Mock");

  const deployer = m.getAccount(0);

  // Deploy ENS Registry
  const ensRegistry = m.contract("LocalENSRegistry", [], { id: "ENS_Registry" });

  const rootNode = "0x0000000000000000000000000000000000000000000000000000000000000000";
  const tldLabel = "name";
  const tldLabelHash = keccak256(toHex(stringToBytes(tldLabel)));
  const tldNode = namehash(tldLabel); // namehash('name')
  
  const domainLabel = "local-curvy";
  const domainLabelHash = keccak256(toHex(stringToBytes(domainLabel)));
  const domainNode = namehash("local-curvy.name");

  const gatewayUrl = "http://localhost:4000/gateway/testnet/{sender}/{callData}.json";

  const gatewayProvider = m.contract("StaticGatewayProvider", [deployer, [gatewayUrl]], {
    id: "ENS_GatewayProvider"
  });

  // Deploy Universal Resolver
  m.contract("LocalUniversalResolver", [deployer, ensRegistry, gatewayProvider], {
    id: "ENS_UniversalResolver"
  });

  // Deploy Offchain Resolver
  const offchainResolver = m.contract("OffchainResolver", [gatewayUrl, [deployer]], {
    id: "ENS_OffchainResolver"
  });

  // Configure ENS

  // Set deployer as owner of ".name" TLD
  const setTldOwner = m.call(ensRegistry, "setSubnodeOwner", [rootNode, tldLabelHash, deployer], { 
    id: "ENS_SetSubnode_Name" 
  });

  // Set deployer as owner of "local-curvy.name" domain
  const setDomainOwner = m.call(ensRegistry, "setSubnodeOwner", [tldNode, domainLabelHash, deployer], { 
    id: "ENS_SetSubnode_LocalCurvy", 
    after: [setTldOwner]
  });

  // Set OffchainResolver as resolver for "local-curvy.name"
  m.call(ensRegistry, "setResolver", [domainNode, offchainResolver], { 
    id: "ENS_SetResolver", 
    after: [setDomainOwner, offchainResolver]
  });

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

  return { erc20Mock, multicall3, curvyVault, portalFactory, ensRegistry, offchainResolver };
});
