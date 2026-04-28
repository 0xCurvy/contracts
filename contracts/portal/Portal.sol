// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {CurvyTypes} from "../utils/Types.sol";
import {ICurvyAggregatorAlphaV2} from "../aggregator-alpha/ICurvyAggregatorAlphaV2.sol";
import {ICurvyVault} from "../vault/ICurvyVault.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPortal} from "./IPortal.sol";

contract Portal is IPortal {
    using SafeERC20 for IERC20;

    uint256 private _ownerHash;
    address private _exitAddress;
    uint256 private _exitChainId;

    address private constant NATIVE_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    ICurvyAggregatorAlphaV2 public curvyAggregator;
    ICurvyVault public curvyVault;

    address public recovery;

    bool private _used;

    modifier onlyRecovery() {
        require(tx.origin == recovery, "Portal: Only recovery");
        _;
    }

    modifier onlyOnce() {
        require(!_used, "SingleUse: Already used");
        _;
        _used = true;
    }

    constructor(uint256 ownerHash, address exitAddress, uint256 exitChainId, address _recovery) {
        if (_recovery == address(0)) revert InvalidRecoveryAddress();
        if ((ownerHash == 0) == (exitAddress == address(0)) || (ownerHash == 0) == (exitChainId == 0)) {
            revert InvalidOwnerHashOrExitBridgeData();
        }

        _ownerHash = ownerHash;
        _exitAddress = exitAddress;
        _exitChainId = exitChainId;
        recovery = _recovery;
    }

    function shield(
        CurvyTypes.Note memory note,
        address curvyAggregatorAlphaProxyAddress,
        address curvyVaultProxyAddress
    ) external onlyOnce {
        if (note.ownerHash != _ownerHash) {
            revert InvalidOwnerHash();
        }

        curvyAggregator = ICurvyAggregatorAlphaV2(curvyAggregatorAlphaProxyAddress);
        curvyVault = ICurvyVault(curvyVaultProxyAddress);

        address tokenAddress = curvyVault.getTokenAddress(note.token);
        
        if (tokenAddress != address(0) && tokenAddress != NATIVE_ETH) {
            IERC20(tokenAddress).forceApprove(address(curvyAggregator), note.amount);
            curvyAggregator.autoShield(note);
        } else {
            curvyAggregator.autoShield{value: note.amount}(note);
        }
    }

    function bridge(address lifiDiamondAddress, bytes calldata bridgeData, uint256 amount, address currency)
        external
        onlyOnce
    {
        // audit(2026-Q1): Missing Address Validation for LiFi Diamond - reject EOAs/zero address
        if (lifiDiamondAddress.code.length == 0) revert InvalidLiFiAddress();

        if (currency != address(0) && currency != NATIVE_ETH) {
            IERC20 token = IERC20(currency);

            uint256 balance = token.balanceOf(address(this));
            if (balance < amount) {
                revert InsufficientBalanceForLiFiBridging();
            }

            token.forceApprove(lifiDiamondAddress, amount);
            // audit(2026-Q1): LiFi error message not propagated - capture revert data
            (bool success, bytes memory result) = lifiDiamondAddress.call(bridgeData);

            if (!success) {
                // audit(2026-Q1): LiFi error message not propagated - bubble up the underlying revert
                if (result.length > 0) {
                    assembly {
                        revert(add(32, result), mload(result))
                    }
                }
                revert BridgeCallFailed();
            }
        } else {
            uint256 balance = address(this).balance;
            if (balance < amount) {
                revert InsufficientBalanceForLiFiBridging();
            }

            // audit(2026-Q1): LiFi error message not propagated - capture revert data
            (bool success, bytes memory result) = lifiDiamondAddress.call{value: amount}(bridgeData);

            if (!success) {
                // audit(2026-Q1): LiFi error message not propagated - bubble up the underlying revert
                if (result.length > 0) {
                    assembly {
                        revert(add(32, result), mload(result))
                    }
                }
                revert BridgeCallFailed();
            }
        }
    }

    function recover(address tokenAddress, address to) external onlyRecovery {
        // audit(2026-Q1): Burning balance during recovery - reject zero destination
        if (to == address(0)) revert InvalidRecoveryAddress();
        // audit(2026-Q1): Lost gas for transaction payment - treat zero address as native ETH (matches bridge)
        if (tokenAddress == NATIVE_ETH || tokenAddress == address(0)) {
            uint256 balance = address(this).balance;
            (bool success,) = to.call{value: balance}("");
            require(success, "Portal: ETH transfer failed");
        } else {
            IERC20 token = IERC20(tokenAddress);
            uint256 balance = token.balanceOf(address(this));
            token.safeTransfer(to, balance);
        }
    }
}
