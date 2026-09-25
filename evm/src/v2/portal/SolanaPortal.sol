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
    error AlreadyInitialized();
    error NoBalance();

    address private constant NATIVE_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    bytes32 private _exitAddress;
    uint256 private _exitChainId;

    address public recovery;

    bool private _used;
    bool private _initialized;

    modifier onlyRecovery() {
        require(tx.origin == recovery, "PortalSolanaExit: Only recovery");
        _;
    }

    modifier onlyOnce() {
        require(!_used, "SingleUse: Already used");
        _;
        _used = true;
    }

    /// @dev Locks the implementation so it cannot be initialized directly.
    /// Proxies start with `_initialized == false` in their own storage.
    constructor() {
        _initialized = true;
    }

    function initialize(bytes32 exitAddress, uint256 exitChainId, address _recovery) external {
        if (_initialized) revert AlreadyInitialized();
        _initialized = true;

        if (_recovery == address(0)) revert InvalidRecoveryAddress();
        if (exitAddress == bytes32(0) || exitChainId == 0) revert InvalidExitBridgeData();

        _exitAddress = exitAddress;
        _exitChainId = exitChainId;
        recovery = _recovery;
    }

    // hasSourceSwaps handling) is performed by PortalFactory before this call.
    function bridge(
        address lifiDiamondAddress,
        bytes calldata bridgeData,
        uint256 amount,
        address currency,
        uint256 gasFee
    ) external payable onlyOnce {
        if (currency != address(0) && currency != NATIVE_ETH) {
            IERC20 token = IERC20(currency);

            uint256 balance = token.balanceOf(address(this));
            if (balance < amount) revert InsufficientBalanceForLiFiBridging();

            token.forceApprove(lifiDiamondAddress, amount);
            // Operator-fronted native fee, forwarded through as msg.value (portal holds no ETH).
            (bool success, bytes memory result) = lifiDiamondAddress.call{value: msg.value}(bridgeData);
            token.forceApprove(lifiDiamondAddress, 0);

            // Reimburse the operator (in `currency`) for the fronted ETH; guarded against 0-transfers.
            if (gasFee > 0) {
                token.safeTransfer(msg.sender, gasFee);
            }

            if (!success) {
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

            (bool success, bytes memory result) = lifiDiamondAddress.call{ value: amount }(bridgeData);

            if (!success) {
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
        if (to == address(0)) revert InvalidRecoveryAddress();
        if (tokenAddress == NATIVE_ETH || tokenAddress == address(0)) {
            uint256 balance = address(this).balance;

            if (balance == 0) {
                revert NoBalance();
            }

            (bool success, ) = to.call{ value: balance }("");
            require(success, "PortalSolanaExit: ETH transfer failed");
        } else {
            IERC20 token = IERC20(tokenAddress);
            uint256 balance = token.balanceOf(address(this));

            if (balance == 0) {
                revert NoBalance();
            }

            token.safeTransfer(to, balance);
        }
    }
}
