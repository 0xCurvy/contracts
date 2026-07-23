// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

import {CurvyTypes} from "../utils/Types.sol";

interface ICurvyVault {

    //#region Events

    event Deposit(address indexed tokenAddress, address indexed to, uint256 amount);
    event Withdraw(address indexed tokenAddress, address indexed to, uint256 amount);
    event TokenRegistration(address token_address, uint256 token_id);
    event TokenDeregistered(address tokenAddress, uint256 tokenId);
    event FeeChange(CurvyTypes.FeeUpdate feeUpdate);
    event CurvyAggregatorAddressChange(address curvyAggregator);
    event FeeCollectorAddressChange(address indexed feeCollectorAddress);

    event CommitmentGasCostsUpdated(CurvyTypes.GasFees[] gasFees, uint256 root);

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
    error NoFeesToCollect();
    error NotAContract();
    error TokenHasOutstandingBalance();
    error FeeTooHigh();
    error InvalidFeeCollectorAddress();
    error GasFeesLengthMismatch();
    error InvalidGasFeeRoot();
    error UnknownGasFeeRoot();
    error UnsortedOrDuplicateTokenId();
    error GasFeeTooLarge();
    error TokenCapacityReached();

    //#endregion

    //#region Public functions

    /// @param gasFeeRecipient EOA that receives the per-token withdrawal gas reimbursement
    ///        (the relayer / `msg.sender` of the aggregator's submitWithdrawalRequest).
    function withdraw(uint256 tokenId, address to, uint256 amount, address gasFeeRecipient) external;
    function deposit(address tokenAddress, address to, uint256 amount) external payable;
    function deregisterToken(address tokenAddress) external;

    //#endregion

    //#region View functions

    function getTokenAddress(uint256 tokenId) external view returns (address);

    function depositFee() external view returns (uint96);
    function withdrawalFee() external view returns (uint96);
    function perTokenGasFees(uint256 tokenId) external view returns (CurvyTypes.GasFees memory fees);

    //#endregion
}
