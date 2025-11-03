// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

import { CurvyTypes } from "../utils/Types.sol";

interface ICurvyVault {
    //#region Events

    event Transfer(address indexed from, address indexed to, uint256 token_id, uint256 amount);
    event TokenRegistration(address token_address, uint256 token_id);
    event NonceChange(address indexed signer, uint256 newNonce);
    event FeeChange(CurvyTypes.MetaTransactionType metaTransactionType, uint96 fee);

    //#endregion

    //#region Public functions

    function transfer(CurvyTypes.MetaTransaction calldata metaTransaction) external;
    function transfer(CurvyTypes.MetaTransaction calldata metaTransaction, bytes memory signature) external;

    //#endregion
}
