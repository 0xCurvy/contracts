// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ENSRegistry } from "./ENSRegistry.sol";
import { ENS } from "./ENS.sol";

// Define the Error signature
error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);

contract LocalENSRegistry is ENSRegistry {}

contract LocalUniversalResolver {
    ENS public immutable registry;
    bytes32 public immutable wildcardNode;

    constructor(ENS _registry, bytes32 _wildcardNode) {
        registry = _registry;
        wildcardNode = _wildcardNode;
    }

    function resolveWithGateways(bytes calldata name, bytes calldata data, string[] calldata)
    external view returns (bytes memory, address)
    {
        return resolve(name, data);
    }

    function resolve(bytes calldata name, bytes calldata data) public view returns (bytes memory, address) {
        bytes32 node = getNode(data);
        address resolverAddr = registry.resolver(node);

        if (resolverAddr == address(0)) {
            resolverAddr = registry.resolver(wildcardNode);
        }

        if (resolverAddr == address(0)) revert("Resolver not found");

        // Call resolve(bytes,bytes)
        bytes memory callPayload = abi.encodeWithSelector(0x9061b923, name, data);
        (bool success, bytes memory result) = resolverAddr.staticcall(callPayload);

        if (!success) {
            // Check for OffchainLookup (0x556f1830)
            if (result.length >= 4) {
                bytes4 selector;
                assembly { selector := mload(add(result, 32)) }

                if (selector == 0x556f1830) {
                    // Patch 'sender' with address(this)
                    assembly {
                        let senderPtr := add(result, 36)
                        mstore(senderPtr, address())
                    }
                }
            }
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return (result, resolverAddr);
    }

    function resolveCallback(bytes calldata response, bytes calldata extraData) external view returns (bytes memory) {
        // 1. Decode the Tuple returned by the Gateway
        //    Tuple: (bytes result, uint64 validUntil, bytes sig)
        (bytes memory result, uint64 validUntil, bytes memory sig) = abi.decode(response, (bytes, uint64, bytes));

        // 2. (Optional) Verify validUntil here
        // if (block.timestamp > validUntil) revert("Signature expired");

        // 3. (Optional) Verify signature 'sig' here using ECDSA

        // 4. Return ONLY the inner result to the DApp
        return result;
    }

    function getNode(bytes calldata data) internal view returns (bytes32 node) {
        if (data.length >= 36) {
            assembly { node := calldataload(add(data.offset, 4)) }
        } else {
            node = wildcardNode;
        }
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x9061b923 || interfaceId == 0x01ffc9a7;
    }
}

contract SimpleOffchainResolver {
    string public url;
    address public signer;

    constructor(string memory _url, address _signer) {
        url = _url;
        signer = _signer;
    }

    function resolve(bytes calldata name, bytes calldata data) external view returns (bytes memory) {
        string[] memory urls = new string[](1);
        urls[0] = url;
        bytes4 callback = LocalUniversalResolver.resolveCallback.selector;

        // Pass msg.data to allow backend to parseTransaction correctly
        revert OffchainLookup(address(this), urls, msg.data, callback, msg.data);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x9061b923 || interfaceId == 0x01ffc9a7;
    }
}