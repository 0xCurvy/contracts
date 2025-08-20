// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICurvyEntrypoint} from "../interfaces/ICurvyEntrypoint.sol";
import {ICSUC} from "../interfaces/ICSUC.sol";

import {CSUC_Types} from "../utils/_Types.sol";
import {CSUC_Constants} from "../utils/_Constants.sol";

/**
 * @title CurvyEntrypoint
 * @author Curvy Protocol (https://curvy.box/)
 * @dev A PoC for the upcoming Curvy Smart Account contract used to enter into main CSUC.
 */
contract CurvyEntrypoint is ICurvyEntrypoint {
    constructor(address _csuc, address _owner) {
        csuc = _csuc;
        owner = _owner;

        if (address(this).balance > 0) {
            require(ICSUC(csuc).wrapNative{value: address(this).balance}(owner), "CurvyEntrypoint: wrapNative failed");
        }
    }

    function enterCSUC(address[] calldata _tokens) public returns (bool) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 _amount = IERC20(_tokens[i]).balanceOf(address(this));
            if (_amount == 0) {
                continue; // No tokens to wrap
            }
            IERC20(_tokens[i]).approve(address(csuc), _amount);
            require(ICSUC(csuc).wrapERC20(owner, _tokens[i], _amount), "CurvyEntrypoint: wrapERC20 failed");
        }
        if (address(this).balance > 0) {
            require(ICSUC(csuc).wrapNative{value: address(this).balance}(owner), "CurvyEntrypoint: wrapNative failed");
        }
        return true;
    }

    address public owner;
    address public csuc;

    using SafeERC20 for IERC20;
}
