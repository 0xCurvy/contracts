// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// audit(operator/authority): role-based access control via OZ AccessControl
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ICurvyVaultV3.sol";
import {CurvyTypes} from "../utils/Types.sol";

contract CurvyVaultV6 is
    ICurvyVaultV3,
    Initializable,
    EIP712Upgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20 for IERC20;

    //#region Constants

    uint256 private constant ETH_ID = 0x1;
    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint96 private constant FEE_DENOMINATOR = 10000;
    // audit(2026-Q1): No upper limit for fee - cap at 10% (1000 / 10000)
    uint96 private constant MAX_FEE = 1000;

    // audit(operator/authority): operational role (collectFees etc.); rotated by AUTHORITY_ROLE
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    // audit(operator/authority): security-critical role (upgrades, registerToken, fees, aggregator address)
    bytes32 public constant AUTHORITY_ROLE = keccak256("AUTHORITY_ROLE");

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
    // audit(2026-Q1): Deprecated fields - was `transferFee`; kept in storage layout, renamed for clarity
    uint96 public __deprecated_transaction_fee;
    uint96 public withdrawalFee;

    address private _curvyAggregator;

    // audit(operator/authority): address fees accumulate to; rotated via setFeeCollectorAddress
    address private _feeCollectorAddress;

    //#endregion

    //#region Modifiers

    // audit(2026-Q1): Modifier instead of error - encode caller restriction in the function signature
    modifier onlyCurvyAggregator() {
        if (msg.sender != _curvyAggregator) revert NotCurvyAggregator();
        _;
    }

    //#endregion

    //#region Init functions

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev DO NOT REMOVE THIS FUNCTION.
     * This function does not affect existing deployments during an upgrade. The `initializer`
     * modifier guarantees it can only be executed once per proxy. When an existing proxy is
     * upgraded to this version, its state is already marked as initialized, making this
     * function safely uncallable and preventing any accidental state resets.
     *
     * The transferFee (now __deprecated_transaction_fee) is unused anymore, but it is kept for storage layout reasons.
     */
    function initialize(address initialOwner) public initializer {
        // Set native currency (ETH) in the token mappings
        _tokenAddressToTokenId[ETH_ADDRESS] = ETH_ID;
        _tokenIdToTokenAddress[ETH_ID] = ETH_ADDRESS;
        _numberOfTokens = 1;

        __EIP712_init("Curvy Privacy Vault", "1.0");
        __Ownable_init(initialOwner);

        // audit(operator/authority): seed roles and fee collector on first deploy
        __AccessControl_init();
        _setRoleAdmin(OPERATOR_ROLE, AUTHORITY_ROLE);
        _setRoleAdmin(AUTHORITY_ROLE, AUTHORITY_ROLE);
        _grantRole(AUTHORITY_ROLE, initialOwner);
        _grantRole(OPERATOR_ROLE, initialOwner);
        _feeCollectorAddress = initialOwner;
        emit FeeCollectorAddressChange(initialOwner);

        depositFee = 10;
        // audit(2026-Q1): Deprecated fields - was `transferFee = 0`
        __deprecated_transaction_fee = 0;
        withdrawalFee = 20;
    }

    // audit(operator/authority): bootstrap AccessControl + fee collector for existing V6 proxies
    function bootstrapAccessControl() external reinitializer(2) onlyOwner {
        __AccessControl_init();
        _setRoleAdmin(OPERATOR_ROLE, AUTHORITY_ROLE);
        _setRoleAdmin(AUTHORITY_ROLE, AUTHORITY_ROLE);
        _grantRole(AUTHORITY_ROLE, owner());
        _grantRole(OPERATOR_ROLE, owner());
        _feeCollectorAddress = owner();
        emit FeeCollectorAddressChange(owner());
    }

    // audit(operator/authority): upgrades gated by AUTHORITY_ROLE
    function _authorizeUpgrade(address) internal override onlyRole(AUTHORITY_ROLE) {}

    //#endregion

    //#region Owner functions

    // audit(operator/authority): authority-gated
    function registerToken(address tokenAddress) external onlyRole(AUTHORITY_ROLE) {
        if (_tokenAddressToTokenId[tokenAddress] != 0) revert TokenAlreadyRegistered();
        // audit(2026-Q1): EOA as tokenAddress - require a deployed contract at the address
        if (tokenAddress.code.length == 0) revert NotAContract();

        // Register ID
        _numberOfTokens++;
        _tokenIdToTokenAddress[_numberOfTokens] = tokenAddress;
        _tokenAddressToTokenId[tokenAddress] = _numberOfTokens;

        // Emit registration event
        emit TokenRegistration(tokenAddress, _numberOfTokens);
    }

    // audit(operator/authority): authority-gated
    function deregisterToken(address tokenAddress) external onlyRole(AUTHORITY_ROLE) {
        uint256 tokenId = _tokenAddressToTokenId[tokenAddress];
        if (tokenId == 0) revert TokenNotRegistered();

        // audit(2026-Q1): Deregister token does not check vault balance - prevent stranding funds
        uint256 vaultBalance = IERC20(tokenAddress).balanceOf(address(this));
        if (vaultBalance != 0) revert TokenHasOutstandingBalance();

        // Remove from both mappings
        _tokenAddressToTokenId[tokenAddress] = 0;
        _tokenIdToTokenAddress[tokenId] = address(0);

        emit TokenDeregistered(tokenAddress, tokenId);
    }

    /**
     * @dev This function is used to set the fees for the vault.
     * @notice If you want to keep the current fee, pass the current fee values.
     */
    // audit(operator/authority): authority-gated
    function setFeeAmount(CurvyTypes.FeeUpdate calldata feeUpdate) external onlyRole(AUTHORITY_ROLE) {
        // audit(2026-Q1): No upper limit for fee - reject fees above MAX_FEE (10%)
        if (feeUpdate.depositFee > MAX_FEE) revert FeeTooHigh();
        if (feeUpdate.withdrawalFee > MAX_FEE) revert FeeTooHigh();

        depositFee = feeUpdate.depositFee;
        withdrawalFee = feeUpdate.withdrawalFee;

        emit FeeChange(feeUpdate);
    }

    // audit(operator/authority): authority-gated
    function setCurvyAggregatorAddress(address curvyAggregator) external onlyRole(AUTHORITY_ROLE) {
        _curvyAggregator = curvyAggregator;
        emit CurvyAggregatorAddressChange(curvyAggregator);
    }

    // audit(operator/authority): authority-gated
    function setFeeCollectorAddress(address newFeeCollectorAddress) external onlyRole(AUTHORITY_ROLE) {
        if (newFeeCollectorAddress == address(0)) revert InvalidFeeCollectorAddress();
        _feeCollectorAddress = newFeeCollectorAddress;
        emit FeeCollectorAddressChange(newFeeCollectorAddress);
    }

    function feeCollectorAddress() external view returns (address) {
        return _feeCollectorAddress;
    }

    // audit(operator/authority): operator-gated; sends to _feeCollectorAddress
    function collectFees(uint256 tokenId) external onlyRole(OPERATOR_ROLE) {
        address tokenAddress = _tokenIdToTokenAddress[tokenId];
        if (tokenAddress == address(0)) {
            revert TokenNotRegistered();
        }

        uint256 amount = _balances[_feeCollectorAddress][tokenId];
        // audit(2026-Q1): Collecting zero fees - skip transfer when nothing to collect
        if (amount == 0) revert NoFeesToCollect();

        _balances[_feeCollectorAddress][tokenId] = 0;

        if (tokenId != ETH_ID) {
            IERC20(tokenAddress).safeTransfer(_feeCollectorAddress, amount);
        } else {
            (bool success,) = _feeCollectorAddress.call{value: amount}("");
            if (!success) revert ETHTransferFailed();
        }
    }

    //#endregion

    //#region Public functions

    function deposit(address tokenAddress, address to, uint256 amount) public payable onlyCurvyAggregator {

        if (to == address(0x0)) revert InvalidRecipient();

        uint256 tokenId;

        if (tokenAddress != ETH_ADDRESS) {
            // We are depositing ERC20
            if (msg.value != 0) revert ERC20TransferFailed();

            tokenId = _tokenAddressToTokenId[tokenAddress];
            if (tokenId == 0) revert TokenNotRegistered();

            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        } else {
            // We are depositing ETH
            if (amount != msg.value) revert ETHTransferFailed();
            tokenId = ETH_ID;
        }

        // audit(2026-Q1): Gas optimization - single balance write per recipient instead of `+=` then `-=`
        // audit(2026-Q1): Wrong data in event - emit truly deposited (post-fee) amount
        // audit(operator/authority): fees go to _feeCollectorAddress
        uint256 depositedAmount = amount;
        if (depositFee != 0) {
            uint256 feeAmount = (amount * depositFee) / FEE_DENOMINATOR;
            depositedAmount = amount - feeAmount;
            _balances[to][tokenId] += depositedAmount;
            _balances[_feeCollectorAddress][tokenId] += feeAmount;
        } else {
            _balances[to][tokenId] += amount;
        }

        emit Deposit(tokenAddress, to, depositedAmount);
    }

    // audit(2026-Q1): Modifier instead of error - replaced inline check with onlyCurvyAggregator
    function withdraw(uint256 tokenId, address to, uint256 amount) external onlyCurvyAggregator {
        if (to == address(0)) revert InvalidRecipient();

        address tokenAddress = _tokenIdToTokenAddress[tokenId];
        if (tokenAddress == address(0)) revert TokenNotRegistered();

        _balances[msg.sender][tokenId] -= amount;

        uint256 amountAfterFees = amount;

        if (withdrawalFee != 0) {
            uint256 feeAmount = (amount * withdrawalFee) / FEE_DENOMINATOR;
            // audit(operator/authority): fees go to _feeCollectorAddress
            _balances[_feeCollectorAddress][tokenId] += feeAmount;

            amountAfterFees -= feeAmount;
        }

        // Withdraw
        if (tokenId != ETH_ID) {
            // We are withdrawing ERC20s
            IERC20(tokenAddress).safeTransfer(to, amountAfterFees);
        } else {
            // We are withdrawing ETH
            (bool success,) = to.call{value: amountAfterFees}("");
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
