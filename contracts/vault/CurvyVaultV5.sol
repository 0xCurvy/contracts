// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ICurvyVaultV2.sol";
import { CurvyTypes } from "../utils/Types.sol";

contract CurvyVaultV5 is ICurvyVaultV2, Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    //#region Constants

    uint256 private constant ETH_ID = 0x1;
    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint96 private constant FEE_DENOMINATOR = 10000;

    bytes32 private constant CURVY_META_TRANSACTION_TYPE_HASH =
        keccak256(
            "CurvyMetaTransaction(uint256 nonce,address from,address to,uint256 tokenId,uint256 amount,uint256 gasFee,uint8 metaTransactionType)"
        );

    //#endregion

    //#region State variables

    mapping(address => mapping(uint256 => uint256)) private _balances;
    mapping(address => uint256) internal _nonces;

    // Number of ERC-20 tokens registered
    uint256 private _numberOfTokens;
    // Maps the ERC-20 contract addresses to their tokenId
    mapping(address => uint256) private _tokenAddressToTokenId;
    // Maps the ERC-20 contract addresses to their tokenId
    mapping(uint256 => address) private _tokenIdToTokenAddress;

    uint96 public depositFee;
    uint96 public transferFee;
    uint96 public withdrawalFee;

    address private _curvyAggregator;

    //#endregion

    //#region Init functions

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        // Set native currency (ETH) in the token mappings
        _tokenAddressToTokenId[ETH_ADDRESS] = ETH_ID;
        _tokenIdToTokenAddress[ETH_ID] = ETH_ADDRESS;
        _numberOfTokens = 1;

        __Ownable_init(initialOwner);

        depositFee = 10;
        withdrawalFee = 20;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    //#endregion

    //#region Owner functions

    function registerToken(address tokenAddress) external onlyOwner {
        if (_tokenAddressToTokenId[tokenAddress] == 0) revert TokenAllreadyRegistered();

        // Register ID
        _numberOfTokens++;
        _tokenIdToTokenAddress[_numberOfTokens] = tokenAddress;
        _tokenAddressToTokenId[tokenAddress] = _numberOfTokens;

        // Emit registration event
        emit TokenRegistration(tokenAddress, _numberOfTokens);
    }

    function unsupportToken(address tokenAddress) external onlyOwner {
        uint256 tokenId = _tokenAddressToTokenId[tokenAddress];
        if (tokenId == 0) revert TokenNotRegistered();

        // Remove from both mappings
        _tokenAddressToTokenId[tokenAddress] = 0;
        _tokenIdToTokenAddress[tokenId] = address(0);

        emit TokenUnsupported(tokenAddress, tokenId);
    }

    function setFeeAmount(CurvyTypes.FeeUpdate calldata feeUpdate) external onlyOwner {
        if (feeUpdate.depositFee != 0) depositFee = feeUpdate.depositFee;
        else if (feeUpdate.withdrawalFee != 0) withdrawalFee = feeUpdate.withdrawalFee;
        else revert NoFeeUpdate();

        emit FeeChange(feeUpdate);
    }

    function setCurvyAggregatorAddress(address curvyAggregator) external onlyOwner {
        _curvyAggregator = curvyAggregator;
        emit CurvyAggregatorAddressChange(curvyAggregator);
    }

    function forceWithdrawal(uint256 amount, address destinationAddress, uint256 tokenId) external onlyOwner {
        if (destinationAddress == address(0)) revert InvalidDestinationAddress();

        // Burn wrapped tokens
        _balances[destinationAddress][tokenId] -= amount;

        address tokenAddress = _tokenIdToTokenAddress[tokenId];
        if (tokenAddress == address(0)) {
            revert TokenNotRegistered();
        }

        if (tokenId != ETH_ID) {
            // We are withdrawing ERC20s
            IERC20(tokenAddress).safeTransfer(destinationAddress, amount);
        } else {
            // We are withdrawing ETH
            (bool success, ) = destinationAddress.call{ value: amount }("");
            if (!success) revert ETHTransferFailed();
        }
    }

    //#endregion

    //#region Public functions

    receive() external payable {
        deposit(ETH_ADDRESS, msg.sender, msg.value, 0);
    }

    function deposit(address tokenAddress, address to, uint256 amount, uint256 gasSponsorshipAmount) public payable {
        if (msg.sender != _curvyAggregator) revert NotCurvyAggregator();

        if (to == address(0x0)) revert InvalidRecipient();

        uint256 tokenId;

        if (tokenAddress != ETH_ADDRESS) {
            // We are depositing ERC20
            if (msg.value != 0) revert ERC20TransferFailed();

            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);

            tokenId = _tokenAddressToTokenId[tokenAddress];
            if (tokenId == 0) revert TokenNotRegistered();
        } else {
            // We are depositing ETH
            if (amount != msg.value) revert ETHTransferFailed();
            tokenId = ETH_ID;
        }

        // Mint wrapped tokens
        _balances[to][tokenId] += amount;

        // Collect fees if they are set
        if (depositFee != 0) {
            uint256 feeAmount = (amount * depositFee) / FEE_DENOMINATOR;
            _balances[to][tokenId] -= feeAmount;
            _balances[owner()][tokenId] += feeAmount;
        }

        // No fees or gas sponsorship deducted from balance (removed per requirements)

        emit Deposit(tokenAddress, to, amount, gasSponsorshipAmount);
    }

    function withdraw(uint256 tokenId, address to, uint256 amount) external {
        if (msg.sender != _curvyAggregator && msg.sender != owner()) revert NotCurvyAggregatorOrOwner();
        if (to == address(0)) revert InvalidRecipient();
        if (withdrawalFee == 0) revert NoFeeUpdate();

        uint256 feeAmount = (amount * withdrawalFee) / FEE_DENOMINATOR;
        // Burn wrapped tokens
        _balances[msg.sender][tokenId] -= amount;
        _balances[owner()][tokenId] += feeAmount;

        address tokenAddress = _tokenIdToTokenAddress[tokenId];
        if (tokenAddress == address(0)) revert TokenNotRegistered();

        // Withdraw
        if (tokenId != ETH_ID) {
            // We are withdrawing ERC20s
            IERC20(tokenAddress).safeTransfer(to, amount - feeAmount);
        } else {
            // We are withdrawing ETH
            (bool success, ) = to.call{ value: amount - feeAmount }("");
            if (!success) revert ETHTransferFailed();
        }

        emit Withdraw(tokenAddress, to, amount);
    }

    //#endregion

    //#region View functions

    function getTokenAddress(uint256 tokenId) public view returns (address tokenAddress) {
        tokenAddress = _tokenIdToTokenAddress[tokenId];
        if (tokenAddress == address(0)) revert TokenNotRegistered();
        return tokenAddress;
    }

    function getTokenId(address tokenAddress) public view returns (uint256 tokenId) {
        tokenId = _tokenAddressToTokenId[tokenAddress];
        if (tokenId == 0) revert TokenNotRegistered();
        return tokenId;
    }

    function getNumberOfTokens() external view returns (uint256) {
        return _numberOfTokens;
    }

    function balanceOf(address owner, uint256 tokenId) external view returns (uint256) {
        return _balances[owner][tokenId];
    }

    //#endregion
}
