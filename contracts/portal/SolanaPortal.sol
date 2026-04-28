// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Single-use portal that bridges its balance to a Solana address via LiFi.
///
/// Mirrors `Portal` for the bridge/recover paths but stores `bytes32 _exitAddress`
/// (a Solana pubkey) instead of an EVM address. Intentionally does not implement
/// `IPortal.shield` — Solana exits never re-enter Curvy. The contract is invoked
/// by `PortalFactory` via an ABI-level cast on the matching `bridge`/`recover`
/// selectors; formal interface inheritance is unnecessary.
contract SolanaPortal {
    using SafeERC20 for IERC20;

    error InvalidRecoveryAddress();
    error InvalidExitBridgeData();
    error InsufficientBalanceForLiFiBridging();
    error BridgeCallFailed();

    address private constant NATIVE_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    bytes32 private _exitAddress;
    uint256 private _exitChainId;

    address public recovery;

    bool private _used;

    modifier onlyRecovery() {
        require(tx.origin == recovery, "PortalSolanaExit: Only recovery");
        _;
    }

    modifier onlyOnce() {
        require(!_used, "SingleUse: Already used");
        _;
        _used = true;
    }

    constructor(bytes32 exitAddress, uint256 exitChainId, address _recovery) {
        if (_recovery == address(0)) revert InvalidRecoveryAddress();
        if (exitAddress == bytes32(0) || exitChainId == 0) revert InvalidExitBridgeData();

        _exitAddress = exitAddress;
        _exitChainId = exitChainId;
        recovery = _recovery;
    }

    // audit(2026-Q1): All LiFi calldata verification (address validity, receiver, destination, amount,
    // hasSourceSwaps handling) is performed by PortalFactory before this call.
    function bridge(
        address lifiDiamondAddress,
        bytes calldata bridgeData,
        uint256 amount,
        address currency
    ) external onlyOnce {
        if (currency != address(0) && currency != NATIVE_ETH) {
            IERC20 token = IERC20(currency);

            uint256 balance = token.balanceOf(address(this));
            if (balance < amount) revert InsufficientBalanceForLiFiBridging();

            token.forceApprove(lifiDiamondAddress, amount);
            // audit(2026-Q1): LiFi error message not propagated - capture revert data
            (bool success, bytes memory result) = lifiDiamondAddress.call(bridgeData);
            // audit(2026-Q1): Difference between amount and note.amount - clear residual approval
            // in case LiFi consumed less than `amount` (refund tokens, partial fill, etc.)
            token.forceApprove(lifiDiamondAddress, 0);

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
            if (balance < amount) revert InsufficientBalanceForLiFiBridging();

            // audit(2026-Q1): LiFi error message not propagated - capture revert data
            (bool success, bytes memory result) = lifiDiamondAddress.call{ value: amount }(bridgeData);

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
            (bool success, ) = to.call{ value: balance }("");
            require(success, "PortalSolanaExit: ETH transfer failed");
        } else {
            IERC20 token = IERC20(tokenAddress);
            uint256 balance = token.balanceOf(address(this));
            token.safeTransfer(to, balance);
        }
    }

    receive() external payable {}
}
