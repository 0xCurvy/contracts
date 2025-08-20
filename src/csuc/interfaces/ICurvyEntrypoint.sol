// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICSUC} from "./ICSUC.sol";

/**
 * @title ICurvyEntrypoint
 * @author Curvy Protocol (https://curvy.box/)
 * @dev An interface for the upcoming Curvy Smart Account contract used to enter into main CSUC.
 */
interface ICurvyEntrypoint {
    function enterCSUC(address[] calldata _tokens) external returns (bool);

    function owner() external view returns (address);
    function csuc() external view returns (address);
}
