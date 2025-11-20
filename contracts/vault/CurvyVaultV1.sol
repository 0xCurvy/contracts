// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ICurvyVault.sol";
import {CurvyTypes} from "../utils/Types.sol";

contract CurvyVaultV1 is ICurvyVault, Initializable, EIP712Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    //#region Constants

    uint256 constant private ETH_ID = 0x1;
    address constant private ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint96 constant private FEE_DENOMINATOR = 10000;

    bytes32 private constant CURVY_META_TRANSACTION_TYPE_HASH = keccak256("CurvyMetaTransaction(uint256 nonce,address from,address to,uint256 tokenId,uint256 amount,uint256 gasFee,uint8 metaTransactionType)");

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

        __EIP712_init("Curvy Privacy Vault", "1.0");
        __Ownable_init(initialOwner);

        depositFee = 10;
        transferFee = 0; // Transfer fee is 0 because we are doing the fee collection for Agg dep/wit on CurvyAggregator.sol
        withdrawalFee = 20;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    //#endregion

    //#region Private functions

    function _validateSignature(CurvyTypes.MetaTransaction calldata metaTransaction, bytes memory signature) internal {
        bytes32 structHash = keccak256(
            abi.encode(
                CURVY_META_TRANSACTION_TYPE_HASH,
                _nonces[metaTransaction.from],
                metaTransaction.from,
                metaTransaction.to,
                metaTransaction.tokenId,
                metaTransaction.amount,
                metaTransaction.gasFee,
                metaTransaction.metaTransactionType
            )
        );

        // Add domain data to the hash
        bytes32 hash = _hashTypedDataV4(structHash);

        // Check that the metaTransaction is signed by metaTransaction.from
        address signer = ECDSA.recover(hash, signature);
        require(signer == metaTransaction.from, "CurvyVault#_validateSignature: Invalid signature!");

        // Increment nonce
        _nonces[signer]++;
        emit NonceChange(signer, _nonces[signer]);
    }

    function _transfer(CurvyTypes.MetaTransaction calldata metaTransaction) private {
        if (metaTransaction.metaTransactionType != CurvyTypes.MetaTransactionType.Transfer) revert InvalidTransactionType();

        address to = metaTransaction.to;

        if (to == address(0)) revert InvalidRecipient();

        uint256 amount = metaTransaction.amount;
        uint256 tokenId = metaTransaction.tokenId;
        address from = metaTransaction.from;

        uint256 userBalance = _balances[from][tokenId];

        if (userBalance < amount) revert InsufficientBalance(userBalance, amount);

        unchecked {
            _balances[from][tokenId] = userBalance - amount;
        }

        uint256 amountToRecipient = amount;
        uint256 gasFee = metaTransaction.gasFee;

        if (gasFee > 0) {
            if (amountToRecipient < gasFee) revert InsufficientAmountForGas();

            unchecked {
                amountToRecipient -= gasFee;
                _balances[msg.sender][tokenId] += gasFee;
            }
        }

        uint256 feeBps = transferFee;

        if (feeBps > 0) {
            // Calculate fee on the GROSS amount
            uint256 protocolFee = (amount * feeBps) / FEE_DENOMINATOR;

            if (amountToRecipient >= protocolFee) {
                unchecked {
                    amountToRecipient -= protocolFee;
                    _balances[owner()][tokenId] += protocolFee;
                }
            } else {
                unchecked {
                    _balances[owner()][tokenId] += amountToRecipient;
                }
                amountToRecipient = 0;
            }
        }

        if (amountToRecipient > 0) {
            unchecked {
                _balances[to][tokenId] += amountToRecipient;
            }
        }

        emit Transfer(from, to, tokenId, amount);
    }

    function _withdraw(CurvyTypes.MetaTransaction calldata metaTransaction) private {
        if (metaTransaction.metaTransactionType != CurvyTypes.MetaTransactionType.Withdraw) revert InvalidTransactionType();

        address to = metaTransaction.to;

        if (to == address(0)) revert InvalidRecipient();

        uint256 amount = metaTransaction.amount;
        uint256 tokenId = metaTransaction.tokenId;
        address from = metaTransaction.from;

        uint256 userBalance = _balances[from][tokenId];

        if (userBalance < amount) revert InsufficientBalance(userBalance, amount);

        unchecked {
            _balances[from][tokenId] = userBalance - amount;
        }

        uint256 amountToSend = amount;
        uint256 gasFee = metaTransaction.gasFee;

        if (gasFee > 0) {
            if (amountToSend < gasFee) revert InsufficientAmountForGas();

            unchecked {
                amountToSend -= gasFee;
                _balances[msg.sender][tokenId] += gasFee;
            }
        }

        uint256 feeBps = withdrawalFee;

        if (feeBps > 0) {
            // Fee is based on ORIGINAL amount (Gross)
            uint256 protocolFee = (amount * feeBps) / FEE_DENOMINATOR;

            if (amountToSend >= protocolFee) {
                unchecked {
                    amountToSend -= protocolFee;
                    _balances[owner()][tokenId] += protocolFee;
                }
            } else {
                // Gas fee reduced amountToSend so much that we can't pay full protocol fee
                // Protocol takes remainder, Recipient gets 0, instead of reverting to avoid griefing
                unchecked {
                    _balances[owner()][tokenId] += amountToSend;
                }
                amountToSend = 0;
            }
        }

        if (amountToSend > 0) {
            if (tokenId != ETH_ID) {
                IERC20(_tokenIdToTokenAddress[tokenId]).safeTransfer(metaTransaction.to, amountToSend);
            } else {
                (bool success,) = metaTransaction.to.call{value: amountToSend}("");
                if (!success) revert ETHTransferFailed();
            }
        }

        emit Transfer(from, to, tokenId, amount);
    }

    //#endregion

    //#region Owner functions

    function registerToken(address tokenAddress) external onlyOwner {
        require(_tokenAddressToTokenId[tokenAddress] == 0, "CurvyVault#registerToken: Token already registered!");

        // Register ID
        _numberOfTokens++;
        _tokenIdToTokenAddress[_numberOfTokens] = tokenAddress;
        _tokenAddressToTokenId[tokenAddress] = _numberOfTokens;

        // Emit registration event
        emit TokenRegistration(tokenAddress, _numberOfTokens);
    }

    function setFeeAmount(CurvyTypes.MetaTransactionType metaTransactionType, uint96 fee) external onlyOwner {
        if (metaTransactionType == CurvyTypes.MetaTransactionType.Deposit) {
            depositFee = fee;
        } else if (metaTransactionType == CurvyTypes.MetaTransactionType.Transfer) {
            transferFee = fee;
        } else if (metaTransactionType == CurvyTypes.MetaTransactionType.Withdraw) {
            withdrawalFee = fee;
        } else {
            revert("CurvyVault#setFeeAmount: Unknown fee type!");
        }

        emit FeeChange(metaTransactionType, fee);
    }

    //#endregion

    //#region Public functions

    receive() external payable {
        deposit(ETH_ADDRESS, msg.sender, msg.value, 0);
    }

    function deposit(address tokenAddress, address to, uint256 amount, uint256 gasSponsorshipAmount) public payable {
        if (to == address(0x0)) revert InvalidRecipient();

        uint256 tokenId;

        if (tokenAddress != ETH_ADDRESS) { // We are depositing ERC20
            require(msg.value == 0, "CurvyVault#deposit: Don't send ETH with ERC20 deposit!");

            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);

            tokenId = _tokenAddressToTokenId[tokenAddress];
            if (tokenId == 0) revert TokenNotRegistered();
        } else { // We are depositing ETH
            require(amount == msg.value, "CurvyVault#deposit: Incorrect deposit value!");
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

        // Collect gas fee when we sponsored by sending you ETH for a primitive gas sponsorship (DEPRECATED)
        if (gasSponsorshipAmount != 0) {
            _balances[to][tokenId] -= gasSponsorshipAmount;
            _balances[owner()][tokenId] += gasSponsorshipAmount;
        }

        emit Transfer(address(0x0), to, tokenId, amount);
    }

    function transfer(CurvyTypes.MetaTransaction calldata metaTransaction) external {
        if (msg.sender != metaTransaction.from) revert InvalidSender();
        if (metaTransaction.gasFee != 0) revert InvalidGasSponsorship();

        _transfer(metaTransaction);
    }

    function transfer(CurvyTypes.MetaTransaction calldata metaTransaction, bytes memory signature) external {
        _validateSignature(metaTransaction, signature);

        _transfer(metaTransaction);
    }

    function withdraw(CurvyTypes.MetaTransaction calldata metaTransaction) external {
        if (msg.sender != metaTransaction.from) revert InvalidSender();
        if (metaTransaction.gasFee != 0) revert InvalidGasSponsorship();

        _withdraw(metaTransaction);
    }

    function withdraw(CurvyTypes.MetaTransaction calldata metaTransaction, bytes memory signature) external {
        _validateSignature(metaTransaction, signature);

        _withdraw(metaTransaction);
    }

    //#endregion

    //#region View functions

    function getTokenAddress(uint256 tokenId) public view returns (address tokenAddress) {
        tokenAddress = _tokenIdToTokenAddress[tokenId];
        if (tokenAddress == address(0x0)) revert TokenNotRegistered();
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

    function balanceOfBatch(address[] memory owners, uint256[] memory tokenIds) external view returns (uint256[] memory) {
        require(owners.length == tokenIds.length, "CurvyVault#balanceOfBatch: Invalid array length!");

        // Variables
        uint256[] memory batchBalances = new uint256[](owners.length);

        // Iterate over each owner and token ID
        for (uint256 i = 0; i < owners.length; i++) {
            batchBalances[i] = _balances[owners[i]][tokenIds[i]];
        }

        return batchBalances;
    }

    function getNonce(address _signer) external view returns (uint256 nonce)
    {
        return _nonces[_signer];
    }

    //#endregion
}