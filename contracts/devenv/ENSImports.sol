// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ENS } from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import { GatewayProvider } from "@ensdomains/ens-contracts/contracts/ccipRead/GatewayProvider.sol";
import { IGatewayProvider } from "@ensdomains/ens-contracts/contracts/universalResolver/AbstractUniversalResolver.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";
import "@ensdomains/ens-contracts/contracts/universalResolver/UniversalResolver.sol";

/**
 * @dev Wrapper za ENSRegistry da bi Hardhat generisao Artifact
 */
contract LocalENSRegistry is ENSRegistry {
    constructor() ENSRegistry() {}
}

contract StaticGatewayProvider is GatewayProvider {
    string[] public gatewayUrls;

    constructor(address owner, string[] memory _urls) GatewayProvider(owner, _urls) {}
}

/**
 * @dev Wrapper za UniversalResolver da bi Hardhat generisao Artifact.
 * Moramo proslediti argumente konstruktora roditelju.
 */
contract LocalUniversalResolver is UniversalResolver {
    constructor(address owner, ENS _registry, IGatewayProvider _urls) UniversalResolver(owner, _registry, _urls) {}
}
