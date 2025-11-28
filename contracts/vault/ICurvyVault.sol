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

    //#region Errors

    error InvalidRecipient();
    error InvalidSender();
    error InvalidTransactionType();
    error InvalidGasSponsorship();
    error TokenNotRegistered();
    error InsufficientBalance(uint256 balance, uint256 required);
    error InsufficientAmountForGas();
    error ETHTransferFailed();

    //#endregion

    //#region Public functions

    function transfer(CurvyTypes.MetaTransaction calldata metaTransaction) external;
    function transfer(CurvyTypes.MetaTransaction calldata metaTransaction, bytes memory signature) external;
    function deposit(address tokenAddress, address to, uint256 amount, uint256 gasSponsorshipAmount) external payable;

    //#endregion

    //#region View functions

    function getTokenAddress(uint256 tokenId) external view returns (address);

    //#endregion
}
