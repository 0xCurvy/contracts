// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
// audit(operator/authority): role-based access control via OZ AccessControl
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { IPortal } from "./IPortal.sol";
import { IPortalFactory, ILiFiCalldataVerification } from "./IPortalFactory.sol";
import { Portal } from "./Portal.sol";
import {SolanaPortal} from "./SolanaPortal.sol";
import { CurvyTypes } from "../utils/Types.sol";

contract PortalFactory is IPortalFactory, Ownable, AccessControl {
    uint256 private constant AGGREGATOR_CHAIN_ID = 42161;

    // audit(operator/authority): operational role (portal deployment); rotated by AUTHORITY_ROLE
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    // audit(operator/authority): security-critical role (updateConfig)
    bytes32 public constant AUTHORITY_ROLE = keccak256("AUTHORITY_ROLE");

    bytes32 private _salt = keccak256(abi.encodePacked("curvy-portal-factory-salt"));

    address private _curvyVaultProxyAddress;
    address private _curvyAggregatorAlphaProxyAddress;
    address private _lifiDiamondAddress;

    // Portals checked for compliance and deployed
    mapping(address => bool) private _registeredPortals;

    constructor(address initialOwner) Ownable(initialOwner) {
        // audit(operator/authority): seed roles. AUTHORITY_ROLE administers both itself and OPERATOR_ROLE.
        _setRoleAdmin(OPERATOR_ROLE, AUTHORITY_ROLE);
        _setRoleAdmin(AUTHORITY_ROLE, AUTHORITY_ROLE);
        _grantRole(AUTHORITY_ROLE, initialOwner);
        _grantRole(OPERATOR_ROLE, initialOwner);
    }

    function deployPortal(bytes memory creationCodeWithArgs) private returns (address) {
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

        return portalAddress;
    }

    // audit(operator/authority): authority-gated
    function updateConfig(
        address curvyVaultProxyAddress,
        address curvyAggregatorAlphaProxyAddress,
        address lifiDiamondAddress
    ) external onlyRole(AUTHORITY_ROLE) returns (bool) {
        // audit(2026-Q1): Missing Smart Contract address check - require code at address (also rejects EOAs and address(0))
        if (curvyVaultProxyAddress.code.length > 0) {
            _curvyVaultProxyAddress = curvyVaultProxyAddress;
        }

        // audit(2026-Q1): Missing Smart Contract address check
        if (curvyAggregatorAlphaProxyAddress.code.length > 0) {
            _curvyAggregatorAlphaProxyAddress = curvyAggregatorAlphaProxyAddress;
        }

        // audit(2026-Q1): Missing Smart Contract address check
        if (lifiDiamondAddress.code.length > 0) {
            _lifiDiamondAddress = lifiDiamondAddress;
        }

        // audit(2026-Q1): No way to query which portals were deployed and when
        emit ConfigUpdated(_curvyVaultProxyAddress, _curvyAggregatorAlphaProxyAddress, _lifiDiamondAddress);

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

    // audit(operator/authority): operator-gated (operational portal deployment)
    function deployShieldPortal(CurvyTypes.Note memory note, address recovery) public payable onlyRole(OPERATOR_ROLE) {
        if (_curvyVaultProxyAddress == address(0) || _curvyAggregatorAlphaProxyAddress == address(0)) {
            revert UnsupportedShielding();
        }

        bytes memory creationCodeWithArgs = getCreationCode(note.ownerHash, address(0), 0, recovery);

        address portalAddress = deployPortal(creationCodeWithArgs);

        _registeredPortals[portalAddress] = true;

        IPortal(portalAddress).shield(note, _curvyAggregatorAlphaProxyAddress, _curvyVaultProxyAddress);

        // audit(2026-Q1): No way to query which portals were deployed and when - emitted after success
        emit ShieldPortalDeployed(portalAddress, note.ownerHash, recovery);
    }

    // audit(operator/authority): operator-gated (operational portal deployment)
    function deployEntryBridgePortal(
        bytes calldata bridgeData,
        CurvyTypes.Note memory note,
        address currency,
        address recovery
    ) public onlyRole(OPERATOR_ROLE) {
        if (_lifiDiamondAddress == address(0)) {
            revert UnsupportedBridging();
        }

        ILiFiCalldataVerification.LiFiBridgeData memory extractedData = ILiFiCalldataVerification(_lifiDiamondAddress)
            .extractBridgeData(bridgeData);

        if (extractedData.receiver != getEntryPortalAddress(note.ownerHash, recovery)) {
            revert InvalidLiFiReceiver();
        }
        if (extractedData.destinationChainId != AGGREGATOR_CHAIN_ID) {
            revert InvalidLiFiDestinationChain();
        }

        bytes memory creationCodeWithArgs = getCreationCode(note.ownerHash, address(0), 0, recovery);

        address portalAddress = deployPortal(creationCodeWithArgs);

        IPortal(portalAddress).bridge(_lifiDiamondAddress, bridgeData, note.amount, currency);

        // audit(2026-Q1): No way to query which portals were deployed and when - emitted after success
        emit EntryBridgePortalDeployed(portalAddress, note.ownerHash, recovery, currency);
    }

    // audit(operator/authority): operator-gated (operational portal deployment)
    function deployExitBridgePortal(
        bytes calldata bridgeData,
        uint256 amount,
        address currency,
        address exitAddress,
        uint256 exitChainId,
        address recovery
    ) public onlyRole(OPERATOR_ROLE) {
        if (_lifiDiamondAddress == address(0)) {
            revert UnsupportedBridging();
        }

        if (exitChainId == block.chainid) {
            ILiFiCalldataVerification.LiFiGenericSwapData memory extractedData = ILiFiCalldataVerification(
                _lifiDiamondAddress
            ).extractGenericSwapParameters(bridgeData);
            if (extractedData.receiver != exitAddress) {
                revert InvalidLiFiReceiver();
            }
        } else {
            ILiFiCalldataVerification.LiFiBridgeData memory extractedData = ILiFiCalldataVerification(
                _lifiDiamondAddress
            ).extractBridgeData(bridgeData);
            if (extractedData.receiver != exitAddress) {
                revert InvalidLiFiReceiver();
            }
            if (extractedData.destinationChainId != exitChainId) {
                revert InvalidLiFiDestinationChain();
            }
        }

        bytes memory creationCodeWithArgs = getCreationCode(0, exitAddress, exitChainId, recovery);

        address portalAddress = deployPortal(creationCodeWithArgs);

        IPortal(portalAddress).bridge(_lifiDiamondAddress, bridgeData, amount, currency);

        // audit(2026-Q1): No way to query which portals were deployed and when - emitted after success
        emit ExitBridgePortalDeployed(portalAddress, exitAddress, exitChainId, recovery, currency);
    }

    function deployRecoveryEntryPortal(uint256 ownerHash, address recovery, address tokenAddress, address to) public {
        bytes memory creationCodeWithArgs = getCreationCode(ownerHash, address(0), 0, recovery);

        address portalAddress = deployPortal(creationCodeWithArgs);

        IPortal(portalAddress).recover(tokenAddress, to);

        // audit(2026-Q1): No way to query which portals were deployed and when - emitted after success
        emit RecoveryPortalDeployed(portalAddress, tokenAddress, to);
    }

    function deployRecoveryExitPortal(
        address exitAddress,
        uint256 exitChainId,
        address recovery,
        address tokenAddress,
        address to
    ) public {
        bytes memory creationCodeWithArgs = getCreationCode(0, exitAddress, exitChainId, recovery);

        address portalAddress = deployPortal(creationCodeWithArgs);

        IPortal(portalAddress).recover(tokenAddress, to);

        // audit(2026-Q1): No way to query which portals were deployed and when - emitted after success
        emit RecoveryPortalDeployed(portalAddress, tokenAddress, to);
    }

    //#region Solana exit

    function getSolanaExitCreationCode(
        bytes32 exitAddress,
        uint256 exitChainId,
        address recovery
    ) public pure returns (bytes memory) {
        bytes memory bytecode = type(SolanaPortal).creationCode;
        bytes memory encodedArgs = abi.encode(exitAddress, exitChainId, recovery);
        return abi.encodePacked(bytecode, encodedArgs);
    }

    function getSolanaExitPortalAddress(
        bytes32 exitAddress,
        uint256 exitChainId,
        address recovery
    ) public view returns (address) {
        bytes memory code = getSolanaExitCreationCode(exitAddress, exitChainId, recovery);
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(code)));
        return address(uint160(uint256(hash)));
    }

    function deploySolanaExitBridgePortal(
        bytes calldata bridgeData,
        uint256 amount,
        address currency,
        bytes32 exitAddress,
        uint256 exitChainId,
        address recovery
    ) public onlyOwner {
        if (_lifiDiamondAddress == address(0)) {
            revert UnsupportedBridging();
        }

        ILiFiCalldataVerification.LiFiBridgeData memory extractedData = ILiFiCalldataVerification(
            _lifiDiamondAddress
        ).extractBridgeData(bridgeData);
        if (extractedData.destinationChainId != exitChainId) {
            revert InvalidLiFiDestinationChain();
        }
        if (_extractNonEVMAddress(bridgeData, extractedData.hasSourceSwaps) != exitAddress) {
            revert InvalidLiFiReceiver();
        }

        bytes memory creationCodeWithArgs = getSolanaExitCreationCode(exitAddress, exitChainId, recovery);

        address portalAddress = deployPortal(creationCodeWithArgs);

        IPortal(portalAddress).bridge(_lifiDiamondAddress, bridgeData, amount, currency);

        // audit(2026-Q1): No way to query which portals were deployed and when - emitted after success
        emit SolanaExitBridgePortalDeployed(portalAddress, exitAddress, exitChainId, recovery, currency);
    }

    /// @dev Mirrors LiFi's `CalldataVerificationFacet.extractNonEVMAddress`.
    /// That function is not deployed on the live diamond, so the logic is
    /// replicated here so the Solana exit path can verify the destination
    /// matches the user-declared `exitAddress`. The receiver is the first
    /// parameter of the bridge-specific data; the head slot that points to it
    /// is `head[2]` when the calldata carries source swaps, otherwise `head[1]`.
    function _extractNonEVMAddress(
        bytes calldata data,
        bool hasSourceSwaps
    ) private pure returns (bytes32 nonEVMAddress) {
        bytes memory callData = data;
        if (hasSourceSwaps) {
            assembly {
                let offset := mload(add(callData, 0x64)) // bridge-specific data offset (head[2])
                nonEVMAddress := mload(add(callData, add(offset, 0x24))) // first word of the bridge-specific struct
            }
        } else {
            assembly {
                let offset := mload(add(callData, 0x44)) // bridge-specific data offset (head[1])
                nonEVMAddress := mload(add(callData, add(offset, 0x24))) // first word of the bridge-specific struct
            }
        }
    }

    function deploySolanaRecoveryExitPortal(
        bytes32 exitAddress,
        uint256 exitChainId,
        address recovery,
        address tokenAddress,
        address to
    ) public {
        bytes memory creationCodeWithArgs = getSolanaExitCreationCode(exitAddress, exitChainId, recovery);

        address portalAddress = deployPortal(creationCodeWithArgs);

        IPortal(portalAddress).recover(tokenAddress, to);

        // audit(2026-Q1): No way to query which portals were deployed and when - emitted after success
        emit SolanaRecoveryPortalDeployed(portalAddress, exitAddress, tokenAddress, to);
    }

    //#endregion
}
