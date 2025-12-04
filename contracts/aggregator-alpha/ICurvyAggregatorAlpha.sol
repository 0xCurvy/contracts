// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

import { CurvyTypes } from "../utils/Types.sol";

interface ICurvyAggregatorAlpha {
    //#region Events

    //#endregion

    //#region Public functions

    function autoShield(CurvyTypes.Note memory note) external payable;

    //#endregion
}
