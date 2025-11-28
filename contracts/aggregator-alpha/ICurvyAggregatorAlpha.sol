// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

import { CurvyTypes } from "../utils/Types.sol";

interface ICurvyAggregatorAlpha {
    //#region Events

    //#endregion

    //#region Public functions

    function depositNote(address from, CurvyTypes.Note memory note) public;

    //#endregion
}
