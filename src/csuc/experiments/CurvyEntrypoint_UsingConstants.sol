// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICSUC} from "../interfaces/ICSUC.sol";

import {CSUC_Types} from "../utils/_Types.sol";
import {CSUC_Constants} from "../utils/_Constants.sol";

/**
 * @title CurvyEntrypoint_UsingConstants
 * @author Curvy Protocol (https://curvy.box/)
 * @dev A PoC for the upcoming Curvy Smart Account contract used to enter into main CSUC.
 */
contract CurvyEntrypoint_UsingConstants {
    constructor() {
        require(ICSUC(csuc).wrapNative{value: address(this).balance}(owner), "CurvyEntrypoint: wrapNative failed");

        for (uint256 i = 0; i < ERC20_TOKENS.length; i++) {
            enterCSUC(ERC20_TOKENS[i]);
        }
    }

    function enterCSUC(address _token) public {
        uint256 _amount = IERC20(_token).balanceOf(address(this));
        if (_amount == 0) {
            return; // No tokens to wrap
        }
        IERC20(_token).approve(address(csuc), _amount);
        ICSUC(csuc).wrapERC20(owner, _token, _amount);
    }

    address public constant owner = address(0xE38316a35cfe43f36779Ee83784FA5d26464f0Ec);
    address public constant csuc = address(0xE38316a35cfe43f36779Ee83784FA5d26464f0Ec);

    address[] public ERC20_TOKENS = [address(0x779877A7B0D9E8603169DdbD7836e478b4624789)];

    using SafeERC20 for IERC20;
}
