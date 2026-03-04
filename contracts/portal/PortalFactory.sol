// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IPortal } from "./IPortal.sol";
import { IPortalFactory, ILiFiCalldataVerification } from "./IPortalFactory.sol";
import { Portal } from "./Portal.sol";
import { CurvyTypes } from "../utils/Types.sol";

contract PortalFactory is IPortalFactory, Ownable {
    uint256 private constant AGGREGATOR_CHAIN_ID = 42161;
    bytes32 private _salt = keccak256(abi.encodePacked("curvy-portal-factory-salt"));

    address private _curvyVaultProxyAddress;
    address private _curvyAggregatorAlphaProxyAddress;
    address private _lifiDiamondAddress;

    // Portals checked for compliance and deployed
    mapping(address => bool) private _registeredPortals;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function updateConfig(
        address curvyVaultProxyAddress,
        address curvyAggregatorAlphaProxyAddress,
        address lifiDiamondAddress
    ) external onlyOwner returns (bool) {
        if (curvyVaultProxyAddress != address(0)) {
            _curvyVaultProxyAddress = curvyVaultProxyAddress;
        }

        if (curvyAggregatorAlphaProxyAddress != address(0)) {
            _curvyAggregatorAlphaProxyAddress = curvyAggregatorAlphaProxyAddress;
        }

        if (lifiDiamondAddress != address(0)) {
            _lifiDiamondAddress = lifiDiamondAddress;
        }

        return true;
    }

    function getCreationCode(
        uint256 ownerHash,
        address exitAddress,
        uint256 exitChainId,
        address recovery
    ) public pure returns (bytes memory) {
        bytes memory bytecode = type(Portal).creationCode;
        bytes memory encodedArgs = abi.encode(ownerHash, exitAddress, exitChainId, recovery);
        return abi.encodePacked(bytecode, encodedArgs);
    }

    function getEntryPortalAddress(uint256 ownerHash, address recovery) public view returns (address) {
        bytes memory code = getCreationCode(ownerHash, address(0), 0, recovery);
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(code)));
        return address(uint160(uint256(hash)));
    }

    function getExitPortalAddress(
        address exitAddress,
        uint256 exitChainId,
        address recovery
    ) public view returns (address) {
        bytes memory code = getCreationCode(0, exitAddress, exitChainId, recovery);
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(code)));
        return address(uint160(uint256(hash)));
    }

    function portalIsRegistered(address portalAddress) public view returns (bool) {
        return _registeredPortals[portalAddress];
    }

    function deployShieldPortal(CurvyTypes.Note memory note, address recovery) public payable onlyOwner {
        if (_curvyVaultProxyAddress == address(0) || _curvyAggregatorAlphaProxyAddress == address(0)) {
            revert UnsupportedShielding();
        }

        bytes memory creationCodeWithArgs = getCreationCode(note.ownerHash, address(0), 0, recovery);
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
            revert DeploymentFailed();
        }

        _registeredPortals[portalAddress] = true;

        IPortal(portalAddress).shield(note, _curvyAggregatorAlphaProxyAddress, _curvyVaultProxyAddress);
    }

    function deployEntryBridgePortal(bytes calldata bridgeData, CurvyTypes.Note memory note, address currency, address recovery) public {
        if (_lifiDiamondAddress == address(0)) {
            revert UnsupportedBridging();
        }

        ILiFiCalldataVerification.LiFiBridgeData memory extractedData = ILiFiCalldataVerification(_lifiDiamondAddress).extractBridgeData(bridgeData);

        if (extractedData.receiver != getEntryPortalAddress(note.ownerHash, recovery)) {
            revert InvalidLiFiReceiver();
        }
        if (extractedData.destinationChainId != AGGREGATOR_CHAIN_ID) {
            revert InvalidLiFiDestinationChain();
        }
        if (extractedData.minAmount > note.amount) {
            revert InsufficientAmountForLiFiBridging();
        }

        bytes memory creationCodeWithArgs = getCreationCode(note.ownerHash, address(0), 0, recovery);
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
            revert DeploymentFailed();
        }

        IPortal(portalAddress).bridge(_lifiDiamondAddress, bridgeData, note.amount, currency);
    }

    function deployExitBridgePortal(
        bytes calldata bridgeData,
        uint256 amount,
        address currency,
        address exitAddress,
        uint256 exitChainId,
        address recovery
    ) public {
        if (_lifiDiamondAddress == address(0)) {
            revert UnsupportedBridging();
        }

        if (exitChainId == block.chainid) {
            ILiFiCalldataVerification.LiFiGenericSwapData memory extractedData = ILiFiCalldataVerification(_lifiDiamondAddress).extractGenericSwapParameters(bridgeData);
            if (extractedData.receiver != exitAddress) {
                revert InvalidLiFiReceiver();
            }
        } else {
            ILiFiCalldataVerification.LiFiBridgeData memory extractedData = ILiFiCalldataVerification(_lifiDiamondAddress)
                .extractBridgeData(bridgeData);
            if (extractedData.receiver != exitAddress) {
                revert InvalidLiFiReceiver();
            }
            if (extractedData.destinationChainId != exitChainId) {
                revert InvalidLiFiDestinationChain();
            }
        }

        bytes memory creationCodeWithArgs = getCreationCode(0, exitAddress, exitChainId, recovery);
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
            revert DeploymentFailed();
        }

        IPortal(portalAddress).bridge(_lifiDiamondAddress, bridgeData, amount, currency);
    }
}
