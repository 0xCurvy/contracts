// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

import {CurvyTypes} from "../utils/Types.sol";

interface ICurvyVaultV3 {
    //#region Events

    event Deposit(address indexed tokenAddress, address indexed to, uint256 amount);
    event Withdraw(address indexed tokenAddress, address indexed to, uint256 amount);
    event TokenRegistration(address token_address, uint256 token_id);
    event TokenDeregistered(address tokenAddress, uint256 tokenId);
    event FeeChange(CurvyTypes.FeeUpdate feeUpdate);
    event CurvyAggregatorAddressChange(address curvyAggregator);

    //#endregion

    //#region Errors

    error InvalidRecipient();
    error NotCurvyAggregator();
    error TokenAlreadyRegistered();
    error InvalidDestinationAddress();
    error TokenNotRegistered();
    error ETHTransferFailed();
    error ERC20TransferFailed();
    error WithdrawalFeeNotSet();
    error NotCurvyAggregatorOrOwner();
    // audit(2026-Q1): Collecting zero fees
    error NoFeesToCollect();

    //#endregion

    //#region Public functions

    function withdraw(uint256 tokenId, address to, uint256 amount) external;
    function deposit(address tokenAddress, address to, uint256 amount) external payable;
    function deregisterToken(address tokenAddress) external;

    //#endregion

    //#region View functions

    function getTokenAddress(uint256 tokenId) external view returns (address);

    function depositFee() external view returns (uint96);
    function withdrawalFee() external view returns (uint96);

    //#endregion
}
