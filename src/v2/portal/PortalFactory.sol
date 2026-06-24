// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

import { IPortal } from "./IPortal.sol";
import { IPortalFactory, ILiFiCalldataVerification } from "./IPortalFactory.sol";
import { Portal } from "./Portal.sol";
import { SolanaPortal } from "./SolanaPortal.sol";
import { CurvyTypes } from "../utils/Types.sol";

contract PortalFactory is IPortalFactory, Ownable, AccessControl {
    uint256 private constant AGGREGATOR_CHAIN_ID = 42161;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant AUTHORITY_ROLE = keccak256("AUTHORITY_ROLE");

    bytes32 private _salt = keccak256(abi.encodePacked("curvy-portal-factory-salt"));

    /// @dev EIP-1167 implementation deployed once at factory construction. All
    /// EVM portals are minimal proxies that delegatecall into this address.
    address public immutable portalImpl;

    /// @dev EIP-1167 implementation for the Solana-exit variant.
    address public immutable solanaPortalImpl;

    address private _curvyVaultProxyAddress;
    address private _curvyAggregatorAlphaProxyAddress;
    address private _lifiDiamondAddress;

    // Portals checked for compliance and deployed
    mapping(address => bool) private _registeredPortals;

    constructor(address initialOwner) Ownable(initialOwner) {
        _setRoleAdmin(OPERATOR_ROLE, AUTHORITY_ROLE);
        _setRoleAdmin(AUTHORITY_ROLE, AUTHORITY_ROLE);
        _grantRole(AUTHORITY_ROLE, initialOwner);
        _grantRole(OPERATOR_ROLE, initialOwner);

        // The impl contracts self-disable initialization in their constructor,
        // so the freshly deployed addresses below are inert templates.
        portalImpl = address(new Portal());
        solanaPortalImpl = address(new SolanaPortal());
    }

    /// @dev Derives a per-portal CREATE2 salt from the static base salt and the
    /// per-portal constructor-equivalent parameters. Under EIP-1167 every clone
    /// shares the same proxy init code, so uniqueness must come from the salt
    /// rather than from constructor args baked into the bytecode.
    function _evmSalt(
        uint256 ownerHash,
        address exitAddress,
        uint256 exitChainId,
        address recovery
    ) private view returns (bytes32) {
        return keccak256(abi.encode(_salt, ownerHash, exitAddress, exitChainId, recovery));
    }

    function _solanaSalt(bytes32 exitAddress, uint256 exitChainId, address recovery) private view returns (bytes32) {
        return keccak256(abi.encode(_salt, exitAddress, exitChainId, recovery));
    }

    function updateConfig(
        address curvyVaultProxyAddress,
        address curvyAggregatorAlphaProxyAddress,
        address lifiDiamondAddress
    ) external onlyRole(AUTHORITY_ROLE) returns (bool) {
        if (curvyVaultProxyAddress.code.length > 0) {
            _curvyVaultProxyAddress = curvyVaultProxyAddress;
        }

        if (curvyAggregatorAlphaProxyAddress.code.length > 0) {
            _curvyAggregatorAlphaProxyAddress = curvyAggregatorAlphaProxyAddress;
        }

        if (lifiDiamondAddress.code.length > 0) {
            _lifiDiamondAddress = lifiDiamondAddress;
        }

        emit ConfigUpdated(_curvyVaultProxyAddress, _curvyAggregatorAlphaProxyAddress, _lifiDiamondAddress);

        return true;
    }

    function getEntryPortalAddress(uint256 ownerHash, address recovery) public view returns (address) {
        return Clones.predictDeterministicAddress(portalImpl, _evmSalt(ownerHash, address(0), 0, recovery));
    }

    function getExitPortalAddress(
        address exitAddress,
        uint256 exitChainId,
        address recovery
    ) public view returns (address) {
        return Clones.predictDeterministicAddress(portalImpl, _evmSalt(0, exitAddress, exitChainId, recovery));
    }

    function portalIsRegistered(address portalAddress) public view returns (bool) {
        return _registeredPortals[portalAddress];
    }

    function deployShieldPortal(CurvyTypes.Note memory note, address recovery) public onlyRole(OPERATOR_ROLE) {
        if (_curvyVaultProxyAddress == address(0) || _curvyAggregatorAlphaProxyAddress == address(0)) {
            revert UnsupportedShielding();
        }

        bytes32 salt = _evmSalt(note.ownerHash, address(0), 0, recovery);
        address portalAddress = Clones.cloneDeterministic(portalImpl, salt);
        IPortal(portalAddress).initialize(note.ownerHash, address(0), 0, recovery);

        _registeredPortals[portalAddress] = true;

        IPortal(portalAddress).shield(note, _curvyAggregatorAlphaProxyAddress, _curvyVaultProxyAddress);

        emit ShieldPortalDeployed(portalAddress, note.ownerHash, recovery);
    }

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

        bytes32 salt = _evmSalt(note.ownerHash, address(0), 0, recovery);
        address portalAddress = Clones.cloneDeterministic(portalImpl, salt);
        IPortal(portalAddress).initialize(note.ownerHash, address(0), 0, recovery);

        IPortal(portalAddress).bridge(_lifiDiamondAddress, bridgeData, note.amount, currency);

        emit EntryBridgePortalDeployed(portalAddress, note.ownerHash, recovery, currency);
    }

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

        bytes32 salt = _evmSalt(0, exitAddress, exitChainId, recovery);
        address portalAddress = Clones.cloneDeterministic(portalImpl, salt);
        IPortal(portalAddress).initialize(0, exitAddress, exitChainId, recovery);

        IPortal(portalAddress).bridge(_lifiDiamondAddress, bridgeData, amount, currency);

        emit ExitBridgePortalDeployed(portalAddress, exitAddress, exitChainId, recovery, currency);
    }

    function deployRecoveryEntryPortal(uint256 ownerHash, address recovery, address tokenAddress, address to) public {
        bytes32 salt = _evmSalt(ownerHash, address(0), 0, recovery);
        address portalAddress = Clones.cloneDeterministic(portalImpl, salt);
        IPortal(portalAddress).initialize(ownerHash, address(0), 0, recovery);

        IPortal(portalAddress).recover(tokenAddress, to);

        emit RecoveryPortalDeployed(portalAddress, tokenAddress, to);
    }

    function deployRecoveryExitPortal(
        address exitAddress,
        uint256 exitChainId,
        address recovery,
        address tokenAddress,
        address to
    ) public {
        bytes32 salt = _evmSalt(0, exitAddress, exitChainId, recovery);
        address portalAddress = Clones.cloneDeterministic(portalImpl, salt);
        IPortal(portalAddress).initialize(0, exitAddress, exitChainId, recovery);

        IPortal(portalAddress).recover(tokenAddress, to);

        emit RecoveryPortalDeployed(portalAddress, tokenAddress, to);
    }

    //#region Solana exit

    function getSolanaExitPortalAddress(
        bytes32 exitAddress,
        uint256 exitChainId,
        address recovery
    ) public view returns (address) {
        return Clones.predictDeterministicAddress(solanaPortalImpl, _solanaSalt(exitAddress, exitChainId, recovery));
    }

    function deploySolanaExitBridgePortal(
        bytes calldata bridgeData,
        uint256 amount,
        address currency,
        bytes32 exitAddress,
        uint256 exitChainId,
        address recovery
    ) public onlyRole(OPERATOR_ROLE) {
        if (_lifiDiamondAddress == address(0)) {
            revert UnsupportedBridging();
        }

        ILiFiCalldataVerification.LiFiBridgeData memory extractedData = ILiFiCalldataVerification(_lifiDiamondAddress)
            .extractBridgeData(bridgeData);
        if (extractedData.destinationChainId != exitChainId) {
            revert InvalidLiFiDestinationChain();
        }
        if (_extractNonEVMAddress(bridgeData, extractedData.hasSourceSwaps) != exitAddress) {
            revert InvalidLiFiReceiver();
        }

        bytes32 salt = _solanaSalt(exitAddress, exitChainId, recovery);
        address portalAddress = Clones.cloneDeterministic(solanaPortalImpl, salt);
        SolanaPortal(portalAddress).initialize(exitAddress, exitChainId, recovery);

        // SolanaPortal exposes the same `bridge` selector as Portal; reuse the IPortal cast.
        IPortal(portalAddress).bridge(_lifiDiamondAddress, bridgeData, amount, currency);

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
        bytes32 salt = _solanaSalt(exitAddress, exitChainId, recovery);
        address portalAddress = Clones.cloneDeterministic(solanaPortalImpl, salt);
        SolanaPortal(portalAddress).initialize(exitAddress, exitChainId, recovery);

        IPortal(portalAddress).recover(tokenAddress, to);

        emit SolanaRecoveryPortalDeployed(portalAddress, exitAddress, tokenAddress, to);
    }

    //#endregion
}
