// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "../aggregator-alpha/ICurvyAggregatorAlpha.sol";
import "./ICurvyVault.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {CurvyTypes} from "../utils/Types.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";



contract CurvyVaultV2 is
    ICurvyVault,
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
    uint96 private constant MAX_FEE = 1000;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
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
    uint96 public withdrawalFee;

    uint256 public constant GAS_TREE_DEPTH = 6;
    uint256 public gasFeeUpdateBlock;

    /// @dev Internal packed gas-fee record. `tokenId` is the mapping key, so it is NOT
    ///      re-stored in the value (the old layout did, costing a full extra — and always
    ///      non-zero — cold storage slot per token). Each cost is a per-token gas
    ///      reimbursement in token base units; uint128 (~3.4e38) is far above any real
    ///      fee. portalDeployment + pendingNoteCommitment share one slot and withdrawal
    ///      takes a second, so a record is 2 slots instead of the previous 4 — halving the
    ///      SSTOREs in `setPerTokenGasFees`.
    struct PackedGasFees {
        uint128 portalDeployment;
        uint128 pendingNoteCommitment;
        uint128 withdrawal;
    }

    mapping(uint256 tokenId => PackedGasFees) internal _perTokenGasFees;

    address private _curvyAggregator;

    address private _feeCollectorAddress;

    //#endregion

    //#region Modifiers

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

        __AccessControl_init();
        _setRoleAdmin(OPERATOR_ROLE, AUTHORITY_ROLE);
        _setRoleAdmin(AUTHORITY_ROLE, AUTHORITY_ROLE);
        _grantRole(AUTHORITY_ROLE, initialOwner);
        _grantRole(OPERATOR_ROLE, initialOwner);
        _feeCollectorAddress = initialOwner;
        emit FeeCollectorAddressChange(initialOwner);

        depositFee = 10;
        withdrawalFee = 20;
    }

    function bootstrapAccessControl() external reinitializer(1) onlyOwner {
        __AccessControl_init();
        _setRoleAdmin(OPERATOR_ROLE, AUTHORITY_ROLE);
        _setRoleAdmin(AUTHORITY_ROLE, AUTHORITY_ROLE);
        _grantRole(AUTHORITY_ROLE, owner());
        _grantRole(OPERATOR_ROLE, owner());
        _feeCollectorAddress = owner();
        emit FeeCollectorAddressChange(owner());
    }

    function _authorizeUpgrade(address) internal override onlyRole(AUTHORITY_ROLE) {}

    //#endregion

    //#region Owner functions

    function registerToken(address tokenAddress) external onlyRole(AUTHORITY_ROLE) {
        if (_tokenAddressToTokenId[tokenAddress] != 0) revert TokenAlreadyRegistered();
        if (tokenAddress.code.length == 0) revert NotAContract();

        // tokenId is the leaf index into the gas-fee tree (capacity 1<<GAS_TREE_DEPTH, indices
        // 0..2^DEPTH-1; index 0 unused). The next id is `_numberOfTokens + 1`, so cap it at the
        // last usable leaf — otherwise its gas cost could never be proven (the circuit constrains
        // token < 2^gasTreeDepth) and `setPerTokenGasFees` would write past the buffer.
        if (_numberOfTokens + 1 >= (1 << GAS_TREE_DEPTH)) revert TokenCapacityReached();

        // Register ID
        _numberOfTokens++;
        _tokenIdToTokenAddress[_numberOfTokens] = tokenAddress;
        _tokenAddressToTokenId[tokenAddress] = _numberOfTokens;

        // Emit registration event
        emit TokenRegistration(tokenAddress, _numberOfTokens);
    }

    function deregisterToken(address tokenAddress) external onlyRole(AUTHORITY_ROLE) {
        uint256 tokenId = _tokenAddressToTokenId[tokenAddress];
        if (tokenId == 0) revert TokenNotRegistered();

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
    function setFeeAmount(CurvyTypes.FeeUpdate calldata feeUpdate) external onlyRole(AUTHORITY_ROLE) {
        if (feeUpdate.depositFee > MAX_FEE) revert FeeTooHigh();
        if (feeUpdate.withdrawalFee > MAX_FEE) revert FeeTooHigh();

        depositFee = feeUpdate.depositFee;
        withdrawalFee = feeUpdate.withdrawalFee;

        emit FeeChange(feeUpdate);
    }


    /// @notice Update the per-token commitment gas costs for the REGISTERED tokens and push the
    ///         matching tree `root` to the aggregator. The gas-fee tree has a fixed capacity of
    ///         `1 << GAS_TREE_DEPTH` leaves; only the first `_numberOfTokens` are ever real, the
    ///         rest are a zero buffer reserved for tokens registered later. So callers pass at most
    ///         one entry per registered token — never the full padded table. Unused buffer leaves
    ///         stay zero, so off-chain consumers reconstruct the whole leaf set from the
    ///         `CommitmentGasCostsUpdated` event by placing each entry at its `tokenId` index and
    ///         zero-filling the rest; pass the full registered set to keep one event self-sufficient.
    function setPerTokenGasFees(
        CurvyTypes.GasFees[] calldata gasFees,
        uint256 commitmentGasFeeRoot
    ) external onlyRole(AUTHORITY_ROLE) {
        if (commitmentGasFeeRoot == 0) revert InvalidGasFeeRoot();

        // Bound by the registered-token count, NOT the tree capacity: only tokens that exist get a
        // real leaf, so we never pay to write the zero buffer (leaves [_numberOfTokens .. 1<<DEPTH)).
        uint256 registered = _numberOfTokens;
        uint256 n = gasFees.length;
        if (n > registered) revert GasFeesLengthMismatch();

        uint256 prevTokenId;
        for (uint256 i = 0; i < n; ) {
            CurvyTypes.GasFees calldata gasFee = gasFees[i];
            uint256 tokenId = gasFee.tokenId;

            // tokenIds are 1.._numberOfTokens (the real leaves); reject 0 / out-of-range.
            if (tokenId == 0 || tokenId > registered) revert TokenNotRegistered();
            if (i != 0 && tokenId <= prevTokenId) revert UnsortedOrDuplicateTokenId();
            prevTokenId = tokenId;

            if (
                gasFee.portalDeployment > type(uint128).max ||
                gasFee.pendingNoteCommitment > type(uint128).max ||
                gasFee.withdrawal > type(uint128).max
            ) revert GasFeeTooLarge();

            _perTokenGasFees[tokenId] = PackedGasFees({
                portalDeployment: uint128(gasFee.portalDeployment),
                pendingNoteCommitment: uint128(gasFee.pendingNoteCommitment),
                withdrawal: uint128(gasFee.withdrawal)
            });
            unchecked {
                ++i;
            }
        }

        ICurvyAggregatorAlpha(_curvyAggregator).setCommitmentGasFeeRoot(commitmentGasFeeRoot);

        gasFeeUpdateBlock = block.number;
        emit CommitmentGasCostsUpdated(gasFees, commitmentGasFeeRoot);
    }

    function setCurvyAggregatorAddress(address curvyAggregator) external onlyRole(AUTHORITY_ROLE) {
        _curvyAggregator = curvyAggregator;
        emit CurvyAggregatorAddressChange(curvyAggregator);
    }

    function setFeeCollectorAddress(address newFeeCollectorAddress) external onlyRole(AUTHORITY_ROLE) {
        if (newFeeCollectorAddress == address(0)) revert InvalidFeeCollectorAddress();
        _feeCollectorAddress = newFeeCollectorAddress;
        emit FeeCollectorAddressChange(newFeeCollectorAddress);
    }

    function feeCollectorAddress() external view returns (address) {
        return _feeCollectorAddress;
    }

    function collectFees(uint256 tokenId) external onlyRole(OPERATOR_ROLE) {
        address tokenAddress = _tokenIdToTokenAddress[tokenId];
        if (tokenAddress == address(0)) {
            revert TokenNotRegistered();
        }

        uint256 amount = _balances[_feeCollectorAddress][tokenId];
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

    function perTokenGasFees(uint256 tokenId) external view override returns (CurvyTypes.GasFees memory fees)
    {
        PackedGasFees storage packed = _perTokenGasFees[tokenId];
        return CurvyTypes.GasFees({
            tokenId: tokenId,
            portalDeployment: packed.portalDeployment,
            pendingNoteCommitment: packed.pendingNoteCommitment,
            withdrawal: packed.withdrawal
        });
    }

    function deposit(address tokenAddress, address to, uint256 amount) public payable onlyCurvyAggregator() {
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

        PackedGasFees storage tokenGasFees = _perTokenGasFees[tokenId];
        // Both costs live in the same packed slot, so this is a single SLOAD.
        uint256 gasFees = uint256(tokenGasFees.pendingNoteCommitment) + tokenGasFees.portalDeployment;

        uint256 depositedAmount = amount - gasFees;
        if (depositFee != 0) {
            uint256 feeAmount = (amount * depositFee) / FEE_DENOMINATOR;
            depositedAmount -= feeAmount;

            _balances[to][tokenId] += depositedAmount;
            _balances[_feeCollectorAddress][tokenId] += feeAmount + gasFees;
        } else {
            _balances[to][tokenId] += depositedAmount;
            _balances[_feeCollectorAddress][tokenId] +=  gasFees;
        }

        emit Deposit(tokenAddress, to, depositedAmount);
    }

    function withdraw(
        uint256 tokenId,
        address to,
        uint256 amount,
        address gasFeeRecipient
    ) external onlyCurvyAggregator {
        if (to == address(0)) revert InvalidRecipient();

        address tokenAddress = _tokenIdToTokenAddress[tokenId];
        if (tokenAddress == address(0)) revert TokenNotRegistered();

        _balances[msg.sender][tokenId] -= amount;

        uint256 amountAfterFees = amount;

        if (withdrawalFee != 0) {
            uint256 feeAmount = (amount * withdrawalFee) / FEE_DENOMINATOR;
            _balances[_feeCollectorAddress][tokenId] += feeAmount;

            amountAfterFees -= feeAmount;
        }

        // Per-token gas reimbursement is paid out to the relayer EOA (gasFeeRecipient), not
        // accrued to the fee collector. The proportional withdrawalFee above still accrues.
        uint256 gasFee = _perTokenGasFees[tokenId].withdrawal;
        amountAfterFees -= gasFee;

        // Withdraw the net to the destination and the gas reimbursement to the relayer.
        if (tokenId != ETH_ID) {
            // We are withdrawing ERC20s
            IERC20(tokenAddress).safeTransfer(to, amountAfterFees);
            if (gasFee > 0) IERC20(tokenAddress).safeTransfer(gasFeeRecipient, gasFee);
        } else {
            // We are withdrawing ETH
            (bool success,) = to.call{value: amountAfterFees}("");
            if (!success) revert ETHTransferFailed();
            if (gasFee > 0) {
                (bool gasSuccess,) = gasFeeRecipient.call{value: gasFee}("");
                if (!gasSuccess) revert ETHTransferFailed();
            }
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
