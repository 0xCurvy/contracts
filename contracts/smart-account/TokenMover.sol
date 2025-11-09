// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ICurvyVault } from "../vault/ICurvyVault.sol";
import "hardhat/console.sol";

contract TokenMover {
    using SafeERC20 for IERC20;

    function moveAllTokens(address tokenAddress, address curvyVaultAddress, uint256 gasSponsorshipAmount) external {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.forceApprove(curvyVaultAddress, balance);

            ICurvyVault curvyVault = ICurvyVault(curvyVaultAddress);
            curvyVault.deposit(tokenAddress, address(this), balance, gasSponsorshipAmount);
        }
    }
}