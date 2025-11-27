// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

import { CurvyTypes } from "../utils/Types.sol";

interface ICurvyAggregatorAlpha {
    //#region Events

    //#endregion

    //#region Public functions

    function depositNote(address from, CurvyTypes.Note memory note, bytes memory signature) public;

    function transfer(CurvyTypes.MetaTransaction calldata metaTransaction) external;
    function transfer(CurvyTypes.MetaTransaction calldata metaTransaction, bytes memory signature) external;
    function deposit(address tokenAddress, address to, uint256 amount, uint256 gasSponsorshipAmount) external payable;

    //#endregion
}
