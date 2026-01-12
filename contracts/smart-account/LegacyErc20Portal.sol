// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LegacyErc20Portal {
    using SafeERC20 for IERC20;

    address constant NATIVE_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function shieldFullBalance(address tokenAddress, address portalAddress) external {
        if (tokenAddress == address(0) || tokenAddress == NATIVE_ETH) {
            revert("Can't shield native tokens.");
        }

        IERC20 token = IERC20(tokenAddress);

        uint256 balance = token.balanceOf(address(this));

        if (balance > 0) {
            token.safeTransfer(portalAddress, balance);
        }
    }
}