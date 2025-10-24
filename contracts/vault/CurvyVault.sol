// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

enum CurvyMetaTransactionType {Withdraw, Transfer, Deposit}

struct CurvyMetaTransaction {
    address from;
    address to;
    uint256 tokenId;
    uint256 amount;
    uint256 gasFee;
    CurvyMetaTransactionType metaTransactionType;
}

contract CurvyVault is Initializable, EIP712Upgradeable {
    using SafeERC20 for IERC20;

    //#region Events
    event Transfer(address indexed from, address indexed to, uint256 token_id, uint256 amount);
    event TokenRegistration(address token_address, uint256 token_id);
    event NonceChange(address indexed signer, uint256 newNonce);
    event FeeChange(CurvyMetaTransactionType metaTransactionType, uint96 fee);
    //#endregion

    //#region Constants
    uint256 constant private ETH_ID = 0x1;
    address constant private ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint96 constant private FEE_DENOMINATOR = 10000;

    bytes32 private constant CURVY_META_TRANSACTION_TYPE_HASH = keccak256("CurvyMetaTransaction(address from, address to, uint256 tokenId, uint256 amount, uint256 gasFee, uint8 metaTransactionType)");
    //#endregion

    //#region State variables
    mapping(address => mapping(uint256 => uint256)) private _balances;
    mapping(address => uint256) private _nonces;

    // Number of ERC-20 tokens registered
    uint256 private _numberOfTokens = 1;
    // Maps the ERC-20 contract addresses to their tokenId
    mapping(address => uint256) private _tokenAddressToTokenId;
    // Maps the ERC-20 contract addresses to their tokenId
    mapping(uint256 => address) private _tokenIdToTokenAddress;

    // Admin is used for:
    // - Collecting Curvy fees
    // - Registering tokens
    // - Changing the fees
    address public admin;

    uint96 public depositFee;
    uint96 public transferFee;
    uint96 public withdrawalFee;
    //#endregion

    //#region Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "");
        _;
    }
    //#endregion

    //#region Init functions
    function initialize() public initializer {
        // Set native currency (ETH) in the token mappings
        _tokenAddressToTokenId[ETH_ADDRESS] = ETH_ID;
        _tokenIdToTokenAddress[ETH_ID] = ETH_ADDRESS;

        __EIP712_init("Curvy Privacy Vault", "1.0");

        depositFee = 10;
        transferFee = 0; // Transfer fee is 0 because we are doing the fee collection for Agg dep/wit on CurvyAggregator.sol
        withdrawalFee = 20;
    }
    //#endregion

    //#region Private functions
    function _burn(address from, uint256 tokenId, uint256 amount) private {
        // Subtract _amount
        _balances[from][tokenId] -= amount;

        // Emit event
        emit Transfer(from, address(0x0), tokenId, amount);
    }

    function _validateSignature(CurvyMetaTransaction calldata metaTransaction, bytes memory signature) internal {
        bytes32 structHash = keccak256(
            abi.encode(
                CURVY_META_TRANSACTION_TYPE_HASH,
                _nonces[metaTransaction.from],
                metaTransaction.from,
                metaTransaction.to,
                metaTransaction.tokenId,
                metaTransaction.amount,
                metaTransaction.gasFee
            )
        );

        // Add domain data to the hash
        bytes32 hash = _hashTypedDataV4(structHash);

        // Check that the metaTransaction is signed by metaTransaction.from
        address signer = ECDSA.recover(hash, signature);
        require(signer == metaTransaction.from, "Invalid signature");

        // Increment nonce
        _nonces[signer]++;
        emit NonceChange(signer, _nonces[signer]);
    }

    function _transfer(CurvyMetaTransaction calldata metaTransaction) private {
        require(metaTransaction.to != address(0), "Invalid recipient for transfer");

        _balances[metaTransaction.from][metaTransaction.tokenId] -= metaTransaction.amount;
        _balances[metaTransaction.to][metaTransaction.tokenId] += metaTransaction.amount;

        // Refund gas if metaTransaction.gasFee is not 0
        if (metaTransaction.gasFee != 0) {
            _balances[metaTransaction.to][metaTransaction.tokenId] -= metaTransaction.gasFee;
            _balances[tx.origin][metaTransaction.tokenId] += metaTransaction.gasFee;
        }

        // Collect fees if they are set
        if (transferFee != 0) {
            uint256 feeAmount = (metaTransaction.amount * transferFee) / FEE_DENOMINATOR;
            _balances[metaTransaction.from][metaTransaction.tokenId] -= feeAmount;
            _balances[admin][metaTransaction.tokenId] += feeAmount;
        }

        emit Transfer(metaTransaction.from, metaTransaction.to, metaTransaction.tokenId, metaTransaction.amount);
    }

    function _withdraw(CurvyMetaTransaction calldata metaTransaction) private {
        require(metaTransaction.to != address(0), "Invalid withdraw recipient");

        // Burn wrapped tokens
        _balances[metaTransaction.from][metaTransaction.tokenId] -= metaTransaction.amount;

        // Refund gas if metaTransaction.gasFee is not 0
        if (metaTransaction.gasFee != 0) {
            _balances[metaTransaction.from][metaTransaction.tokenId] -= metaTransaction.gasFee;
            _balances[tx.origin][metaTransaction.tokenId] += metaTransaction.gasFee;
        }

        // Collect fees if they are set
        if (withdrawalFee != 0) {
            uint256 feeAmount = (metaTransaction.amount * withdrawalFee) / FEE_DENOMINATOR;
            _balances[metaTransaction.from][metaTransaction.tokenId] -= feeAmount;
            _balances[admin][metaTransaction.tokenId] += feeAmount;
        }

        // Withdraw
        if (metaTransaction.tokenId != ETH_ID) { // We are withdrawing ERC20s
            address tokenAddress = _tokenIdToTokenAddress[metaTransaction.tokenId];
            IERC20(tokenAddress).safeTransfer(metaTransaction.to, metaTransaction.amount);
        } else { // We are withdrawing ETH
            (bool success,) = metaTransaction.to.call{value: metaTransaction.amount}("");
            require(success, "ETH withdrawal failed");
        }

        emit Transfer(metaTransaction.from, address(0x0), metaTransaction.tokenId, metaTransaction.amount);
    }

    //#endregion

    //#region Admin functions
    function registerToken(address tokenAddress) external onlyAdmin {
        require(_tokenAddressToTokenId[tokenAddress] == 0, "Token already registered");

        // Register ID
        _numberOfTokens++;
        _tokenIdToTokenAddress[_numberOfTokens] = tokenAddress;
        _tokenAddressToTokenId[tokenAddress] = _numberOfTokens;

        // Emit registration event
        emit TokenRegistration(tokenAddress, _numberOfTokens);
    }

    function setFeeAmount(CurvyMetaTransactionType metaTransactionType, uint96 fee) external onlyAdmin {
        if (metaTransactionType == CurvyMetaTransactionType.Deposit) {
            depositFee = fee;
        } else if (metaTransactionType == CurvyMetaTransactionType.Transfer) {
            transferFee = fee;
        } else if (metaTransactionType == CurvyMetaTransactionType.Withdraw) {
            withdrawalFee = fee;
        } else {
            revert("Unknown fee type");
        }

        emit FeeChange(metaTransactionType, fee);
    }
    //#endregion

    //#region Public functions

    receive() external payable {
        deposit(ETH_ADDRESS, msg.sender, msg.value);
    }

    function deposit(address tokenAddress, address to, uint256 amount) public payable {
        require(to != address(0x0), "Invalid recipient for deposit");

        uint256 tokenId;

        if (tokenAddress != ETH_ADDRESS) { // We are depositing ERC20
            require(msg.value == 0, "Don't send ETH with ERC20 deposit");

            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);

            tokenId = _tokenAddressToTokenId[tokenAddress];
            require(tokenId != 0, "Token address not registered");
        } else { // We are depositing ETH
            require(amount == msg.value, "Incorrect deposit value.");
            tokenId = ETH_ID;
        }

        // Mint wrapped tokens
        _balances[to][tokenId] += amount;

        // Collect fees if they are set
        if (depositFee != 0) {
            uint256 feeAmount = (amount * depositFee) / FEE_DENOMINATOR;
            _balances[to][tokenId] -= feeAmount;
            _balances[admin][tokenId] += feeAmount;
        }

        emit Transfer(address(0x0), to, tokenId, amount);
    }

    function transfer(CurvyMetaTransaction calldata metaTransaction) external {
        require(msg.sender == metaTransaction.from, "Invalid msg.sender");
        require(metaTransaction.gasFee == 0, "gasFee must be 0 when not relaying metaTransaction for others");

        _transfer(metaTransaction);
    }

    function transfer(CurvyMetaTransaction calldata metaTransaction, bytes memory signature) external {
        require(metaTransaction.metaTransactionType == CurvyMetaTransactionType.Withdraw, "Wrong type for meta transaction");

        _validateSignature(metaTransaction, signature);

        _transfer(metaTransaction);
    }

    function withdraw(CurvyMetaTransaction calldata metaTransaction) external {
        require(msg.sender == metaTransaction.from, "Invalid msg.sender");
        require(metaTransaction.gasFee == 0, "gasFee must be 0 when not relaying metaTransaction for others");

        _withdraw(metaTransaction);
    }

    function withdraw(CurvyMetaTransaction calldata metaTransaction, bytes memory signature) external {
        require(metaTransaction.metaTransactionType == CurvyMetaTransactionType.Withdraw, "Wrong type for meta transaction");
        _validateSignature(metaTransaction, signature);

        _withdraw(metaTransaction);
    }

    //#endregion

    //#region View functions

    function getTokenAddress(uint256 _id) public view returns (address token) {
        token = _tokenIdToTokenAddress[_id];
        require(token != address(0x0), "MetaERC20Wrapper#getIdAddress: UNREGISTERED_TOKEN");
        return token;
    }

    function getTokenID(address tokenId) public view returns (uint256 tokenID) {
        tokenID = _tokenAddressToTokenId[tokenId];
        require(tokenID != 0, "MetaERC20Wrapper#getTokenID: UNREGISTERED_TOKEN");
        return tokenID;
    }

    function getNumberOfTokens() external view returns (uint256) {
        return _numberOfTokens;
    }

    function balanceOf(address owner, uint256 tokenId) external view returns (uint256) {
        return _balances[owner][tokenId];
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory tokenIds) external view returns (uint256[] memory) {
        require(owners.length == tokenIds.length, "Invalid array length");

        // Variables
        uint256[] memory batchBalances = new uint256[](owners.length);

        // Iterate over each owner and token ID
        for (uint256 i = 0; i < owners.length; i++) {
            batchBalances[i] = _balances[owners[i]][tokenIds[i]];
        }

        return batchBalances;
    }

    //#endregion
}