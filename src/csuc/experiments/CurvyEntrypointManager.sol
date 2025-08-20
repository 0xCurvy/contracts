// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICSUC} from "../interfaces/ICSUC.sol";
import {ICurvyEntrypoint} from "../interfaces/ICurvyEntrypoint.sol";

import {CSUC_Types} from "../utils/_Types.sol";
import {CSUC_Constants} from "../utils/_Constants.sol";

/**
 * @title CurvyEntrypoint
 * @author Curvy Protocol (https://curvy.box/)
 * @dev A PoC for the upcoming Curvy Smart Account Manager contract used to intro multiple Users into main CSUC.
 */
contract CurvyEntrypointManager {
    function enterCSUC(CSUC_Target[] calldata _targets) public {
        for (uint256 i = 0; i < _targets.length; ++i) {
            ICurvyEntrypoint(_targets[i].target).enterCSUC(_targets[i].token);
        }
    }

    struct CSUC_Target {
        address target;
        address[] token;
    }

    using SafeERC20 for IERC20;
}
