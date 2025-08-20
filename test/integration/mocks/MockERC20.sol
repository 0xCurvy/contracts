// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockERC20
 * @author Curvy Protocol (https://curvy.box/)
 * @dev A mock ERC20 token for testing purposes.
 */
contract MockERC20 is ERC20 {
    constructor(uint256 _totalSupply) ERC20("MockERC20", "M20") {
        _mint(msg.sender, _totalSupply);
    }
}
