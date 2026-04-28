// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

import {CurvyTypes} from "../utils/Types.sol";

interface ICurvyAggregatorAlphaV2 {
    //#region Errors

    error PortalNotRegistered();
    error NoteNotScheduledForDeposit();
    error InvalidNotesRoot();
    error InvalidProof();
    error CurrentNoteTreeRootMismatch();
    error CurrentNullifierTreeRootMismatch();
    error InvalidWithdrawProof();

    // audit: deposit-batch-commit visibility for off-chain indexers and monitoring
    event DepositBatchCommitted(uint256 indexed oldNotesRoot, uint256 indexed newNotesRoot);

    //#endregion

    //#region Public functions

    function autoShield(CurvyTypes.Note memory note) external payable;

    //#endregion
}
