// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LegacyPortal {
    using SafeERC20 for IERC20;

    address internal constant NATIVE_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal immutable owner;

    error Unauthorized();
    error EthTransferFailed();

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    function shieldFullBalance(address tokenAddress, address portalAddress) external onlyOwner{
        if (tokenAddress != address(0) && tokenAddress != NATIVE_ETH) {
            IERC20 token = IERC20(tokenAddress);

            uint256 balance = token.balanceOf(address(this));

            if (balance > 0) {
                token.safeTransfer(portalAddress, balance);
            }
        } else {
            uint256 balance = address(this).balance;

            if (balance > 0) {
                (bool success, ) = portalAddress.call{ value: balance }("");

                if (!success) {
                    revert EthTransferFailed();
                }
            }
        }
    }
}