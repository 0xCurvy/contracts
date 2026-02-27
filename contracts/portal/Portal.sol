// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {CurvyTypes} from "../utils/Types.sol";
import {ICurvyAggregatorAlpha} from "../aggregator-alpha/ICurvyAggregatorAlpha.sol";
import {ICurvyVault} from "../vault/ICurvyVault.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPortal} from "./IPortal.sol";
import {SingleUse} from "../utils/SingleUse.sol";

contract Portal is IPortal, SingleUse {
    using SafeERC20 for IERC20;

    uint256 private _ownerHash;
    address private _exitAddress;
    uint256 private _exitChainId;

    address private constant NATIVE_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant AGGREGATOR_CHAIN_ID = 42161;

    ICurvyAggregatorAlpha public curvyAggregator;
    ICurvyVault public curvyVault;

    address public recovery;

    modifier onlyRecovery() {
        require(msg.sender == recovery, "Portal: Only recovery");
        _;
    }

    constructor(uint256 ownerHash, address exitAddress, uint256 exitChainId, address _recovery) {
        // TODO: add fee for deployment
        if (_recovery == address(0)) revert InvalidRecoveryAddress();
        if ((ownerHash == 0) == (exitAddress == address(0)) || (ownerHash == 0) == (exitChainId == 0)) revert InvalidOwnerHashOrExitBridgeData();

        _ownerHash = ownerHash;
        _exitAddress = exitAddress;
        _exitChainId = exitChainId;
        recovery = _recovery;
    }

    /**
     * @dev Use this if the bridgeCallData is purely the ABI-encoded struct
     * (e.g., it was encoded using abi.encode(bridgeData))
     */
    function _decodeBridgeDataStruct(bytes calldata bridgeCallData) internal pure returns (LiFiBridgeData memory) {
        return abi.decode(bridgeCallData, (LiFiBridgeData));
    }

    /**
     * @dev Use this if the bridgeCallData is a full transaction payload
     * where the struct is the very first parameter after the 4-byte function selector.
     */
    function _decodeBridgeData(bytes calldata txData) internal pure returns (LiFiBridgeData memory) {
        // The first 4 bytes are the function selector, so we skip them
        return abi.decode(txData[4:], (LiFiBridgeData));
    }

    function _bridge(address lifiDiamondAddress, bytes calldata bridgeData, address sendingAssetId, uint256 amount) internal {
        if (lifiDiamondAddress == address(0)) {
            revert InvalidLiFiAddress();
        }
        
        if (sendingAssetId != address(0) && sendingAssetId != NATIVE_ETH) {
            IERC20 token = IERC20(sendingAssetId);

            uint256 balance = token.balanceOf(address(this));
            if (balance < amount) {
                revert InsufficientBalanceForLiFiBridging();
            }

            token.forceApprove(lifiDiamondAddress, amount);
            (bool success,) = lifiDiamondAddress.call(bridgeData);

            if (!success) {
                revert BridgeCallFailed();
            }
        } else {
            uint256 balance = address(this).balance;
            if (balance < amount) {
                revert InsufficientBalanceForLiFiBridging();
            }

            (bool success,) = lifiDiamondAddress.call{value: amount}(bridgeData);

            if (!success) {
                revert BridgeCallFailed();
            }
        }
    }

    function shield(
        CurvyTypes.Note memory note,
        address curvyAggregatorAlphaProxyAddress,
        address curvyVaultProxyAddress
    ) external onlyOnce {
        if (note.ownerHash != _ownerHash) {
            revert InvalidOwnerHash();
        }

        curvyAggregator = ICurvyAggregatorAlpha(curvyAggregatorAlphaProxyAddress);
        curvyVault = ICurvyVault(curvyVaultProxyAddress);

        address tokenAddress;
        try curvyVault.getTokenAddress(note.token) returns (address _tokenAddress) {
            tokenAddress = _tokenAddress;
        } catch {
            emit ShieldingFailed(note.ownerHash, tokenAddress, note.amount, "Failed to get token address from vault");
            // Here we just do a return because we want the deployment to pass so that the user can call the recover method.
            return;
        }
        if (tokenAddress != address(0) && tokenAddress != NATIVE_ETH) {
            IERC20(tokenAddress).forceApprove(address(curvyAggregator), note.amount);
            curvyAggregator.autoShield(note, tokenAddress);
        } else {
            curvyAggregator.autoShield{value: note.amount}(note, tokenAddress);
        }
    }

    function recover(address tokenAddress, address to) external onlyRecovery {
        if (tokenAddress == NATIVE_ETH) {
            uint256 balance = address(this).balance;
            (bool success,) = to.call{value: balance}("");
            require(success, "Portal: ETH transfer failed");
        } else {
            IERC20 token = IERC20(tokenAddress);
            uint256 balance = token.balanceOf(address(this));
            token.safeTransfer(to, balance);
        }
    }

    function entryBridge(address lifiDiamondAddress, bytes calldata bridgeData, CurvyTypes.Note memory note)
        external
        onlyOnce
    {
        if (note.ownerHash != _ownerHash) {
            revert InvalidOwnerHash();
        }

        LiFiBridgeData memory data = _decodeBridgeData(bridgeData);

        if (data.receiver != address(this)) {
            revert InvalidLiFiReceiver();
        }

        if (data.destinationChainId != AGGREGATOR_CHAIN_ID) {
            revert InvalidLiFiDestinationChain();
        }

        if (data.minAmount > note.amount) {
            revert InsufficientAmountForLiFiBridging();
        }

        _bridge(lifiDiamondAddress, bridgeData, data.sendingAssetId, note.amount);
    }

    function exitBridge(address lifiDiamondAddress, uint256 amount, bytes calldata bridgeData)
        external
        onlyOnce
    {
        LiFiBridgeData memory data = _decodeBridgeDataStruct(bridgeData);

        if (data.receiver != _exitAddress) {
            revert InvalidLiFiReceiver();
        }

        if (data.destinationChainId != _exitChainId) {
            revert InvalidLiFiDestinationChain();
        }

        _bridge(lifiDiamondAddress, bridgeData, data.sendingAssetId, amount);
    }
}
