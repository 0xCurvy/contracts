// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenBridge {
    using SafeERC20 for IERC20;

    address constant NATIVE_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private _lifiDiamondAddress;

    constructor(address lifiDiamondAddress)  {
        _lifiDiamondAddress = lifiDiamondAddress;
    }

    function bridgeFullBalance(address tokenAddress, bytes calldata bridgeData) external {
        if (_lifiDiamondAddress == address(0)) {
            revert("TokenBridge: Invalid LI.FI address");
        }

        if (tokenAddress != address(0) && tokenAddress != NATIVE_ETH) {
            IERC20 token = IERC20(tokenAddress);

            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                token.forceApprove(_lifiDiamondAddress, balance);
                (bool success, ) = _lifiDiamondAddress.call(bridgeData);

                if (!success) {
                    revert("TokenBridge: Bridge call failed");
                }
            }
        } else {
            uint256 balance = address(this).balance;
            if (balance > 0) {
                (bool success, ) = _lifiDiamondAddress.call{ value: balance }(bridgeData);

                if (!success) {
                    revert("TokenBridge: Bridge call failed");
                }
            }
        }
    }
}