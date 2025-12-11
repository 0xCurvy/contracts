// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

import { CurvyTypes } from "../utils/Types.sol";

interface ICurvyAggregatorAlpha {
    function autoShield(CurvyTypes.Note memory note, address tokenAddress) external payable;
}
