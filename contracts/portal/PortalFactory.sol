// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IPortal } from "./IPortal.sol";
import { Portal } from "./Portal.sol";
import { CurvyTypes } from "../utils/Types.sol";

contract PortalFactory is Ownable {
    bytes32 private _salt = keccak256(abi.encodePacked("curvy-portal-factory-salt"));

    address private _curvyVaultProxyAddress;
    address private _curvyAggregatorAlphaProxyAddress;
    address private _lifiDiamondAddress;
    uint256 private _aggregatorChainId;

    constructor(address initialOwner, address curvyVaultProxyAddress, address curvyAggregatorAlphaProxyAddress, uint256 aggregatorChainId) Ownable(initialOwner) {
        _aggregatorChainId = aggregatorChainId;
        _curvyVaultProxyAddress = curvyVaultProxyAddress;
        _curvyAggregatorAlphaProxyAddress = curvyAggregatorAlphaProxyAddress;
    }

    function updateLifiDiamondAddress(address lifiDiamondAddress) external onlyOwner returns (bool) {
        _lifiDiamondAddress = lifiDiamondAddress;
        return true;
    }

    function getCreationCode(uint256 ownerHash, address recovery) public pure returns (bytes memory) {
        bytes memory bytecode = type(Portal).creationCode;
        bytes memory encodedArgs = abi.encode(ownerHash, recovery);
        return abi.encodePacked(bytecode, encodedArgs);
    }

    function getPortalAddress(uint256 ownerHash, address recovery) public view returns (address) {
        bytes memory code = getCreationCode(ownerHash, recovery);
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(code)));
        return address(uint160(uint256(hash)));
    }

    function deployAndShield(CurvyTypes.Note memory note, address recovery) public payable {
        if (block.chainid != _aggregatorChainId) {
            revert("PortalFactory: Shielding not supported on this chain");
        }

        bytes memory creationCodeWithArgs = getCreationCode(note.ownerHash, recovery);
        address portalAddress;

        bytes32 salt = _salt;

        assembly {
            // Deploy using CREATE2: value in wei, data pointer, data length, salt
            portalAddress := create2(
                callvalue(), // value to send
                add(creationCodeWithArgs, 0x20), // pointer to start of bytecode
                mload(creationCodeWithArgs), // length of bytecode
                salt // the salt
            )
        }
        if (portalAddress == address(0)) {
            revert("PortalFactory: Deployment failed");
        }

        IPortal(portalAddress).shield(note, _curvyAggregatorAlphaProxyAddress, _curvyVaultProxyAddress);
    }

    function deployAndBridge(
        bytes calldata bridgeData,
        CurvyTypes.Note memory note,
        address tokenAddress,
        address recovery
    ) public {
        if (_lifiDiamondAddress == address(0) || block.chainid == _aggregatorChainId) {
            revert("PortalFactory: Bridging not supported on this chain");
        }

        bytes memory creationCodeWithArgs = getCreationCode(note.ownerHash, recovery);
        address portalAddress;

        bytes32 salt = _salt;

        assembly {
            // Deploy using CREATE2: value in wei, data pointer, data length, salt
            portalAddress := create2(
                callvalue(), // value to send
                add(creationCodeWithArgs, 0x20), // pointer to start of bytecode
                mload(creationCodeWithArgs), // length of bytecode (will load what we skip in previous argument)
                salt // the salt
            )
        }
        if (portalAddress == address(0)) {
            revert("PortalFactory: Deployment failed");
        }

        IPortal(portalAddress).bridge(_lifiDiamondAddress, bridgeData, note, tokenAddress);
    }
}
