// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { IPortalFactory } from "../portal/IPortalFactory.sol";
import {
    ICurvyInsertionVerifier,
    ICurvyAggregationVerifier,
    ICurvyWithdrawVerifierV3
} from "../aggregator-alpha/verifiers/ICurvyVerifiersAlpha.sol";
import { CurvyTypes } from "../utils/Types.sol";
import { ICurvyAggregatorAlpha } from "./ICurvyAggregatorAlpha.sol";
import { ICurvyVault } from "../vault/ICurvyVault.sol";
import { PoseidonT4 } from "../aggregator-alpha/utils/PoseidonT4.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice V2 insertion verifier: 2 public signals — [newNotesRoot, inputHash].
interface ICurvyInsertionVerifierV2 {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory input
    ) external view returns (bool);
}

/**
 * @title CurvyAggregatorAlphaV2
 * @author Curvy Protocol (https://curvy.box)
 * @dev V2 aggregator: per-note lifecycle mapping, validNotesRoot anchor, per-request aggregation/withdrawal.
 *      Covers PRD-008 (deposits), PRD-009 (withdrawals), PRD-010 (aggregation).
 */
contract CurvyAggregatorAlphaV2 is
    ICurvyAggregatorAlpha,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20 for IERC20;

    address constant NATIVE_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant AUTHORITY_ROLE = keccak256("AUTHORITY_ROLE");

    //#region State

    uint256 public maxDeposits;
    uint256 public maxAggregations;
    uint256 public maxWithdrawals;

    // Per-note lifecycle. UNKNOWN -> PENDING (autoShield / aggregation outputs) -> INCLUDED (commitPendingNotes).
    mapping(uint256 noteId => NoteStatus) public noteStatus;

    // Every notes-tree root ever anchored by commitPendingNotes.
    mapping(uint256 root => bool) public validNotesRoot;

    // Flat nullifier sets (replace SMT for v2 paths).
    mapping(uint256 nullifier => bool) public aggregationNullifiers;
    mapping(uint256 nullifier => bool) public withdrawalNullifiers;

    // Head of the notes tree (latest root anchored).
    uint256 private _currentNotesTreeRoot;
    uint256 private _currentNotesBatchIndex;
    uint256 private _currentNullifiersBatchIndex;

    // Protocol-level fee accounting (mirrors Vault config; final source-of-truth lives in Vault).
    uint256 public protocolFee;
    uint256 public gasFee;

    ICurvyVault public curvyVault;
    ICurvyInsertionVerifier public insertionVerifier;
    ICurvyAggregationVerifier public aggregationVerifier;
    ICurvyWithdrawVerifierV3 public withdrawVerifier;
    IPortalFactory public portalFactory;

    // Append-only storage (UUPS-safe).
    // Tracks the next free leaf index in the notes tree.
    uint256 private _currentNoteIndex;

    // Insertion verifier per (batchSize, treeDepth). Allows operating multiple
    // compiled circuit instances concurrently — caller picks the matching pair.
    mapping(bytes32 configKey => ICurvyInsertionVerifierV2) public insertionVerifiersByConfig;

    //#endregion

    //#region Init

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __AccessControl_init();
        _setRoleAdmin(OPERATOR_ROLE, AUTHORITY_ROLE);
        _setRoleAdmin(AUTHORITY_ROLE, AUTHORITY_ROLE);
        _grantRole(AUTHORITY_ROLE, initialOwner);
        _grantRole(OPERATOR_ROLE, initialOwner);
    }

    function _authorizeUpgrade(address) internal override onlyRole(AUTHORITY_ROLE) {}

    //#endregion

    //#region Admin

    function updateConfig(
        CurvyTypes.AggregatorConfigurationUpdate memory _update
    ) external onlyRole(AUTHORITY_ROLE) returns (bool) {
        if (_update.insertionVerifier.code.length > 0)
            insertionVerifier = ICurvyInsertionVerifier(_update.insertionVerifier);
        if (_update.aggregationVerifier.code.length > 0)
            aggregationVerifier = ICurvyAggregationVerifier(_update.aggregationVerifier);
        if (_update.withdrawVerifier.code.length > 0)
            withdrawVerifier = ICurvyWithdrawVerifierV3(_update.withdrawVerifier);
        if (_update.curvyVault.code.length > 0) curvyVault = ICurvyVault(_update.curvyVault);
        if (_update.portalFactory.code.length > 0) portalFactory = IPortalFactory(_update.portalFactory);
        if (_update.maxDeposits != 0) maxDeposits = _update.maxDeposits;
        if (_update.maxAggregations != 0) maxAggregations = _update.maxAggregations;
        if (_update.maxWithdrawals != 0) maxWithdrawals = _update.maxWithdrawals;
        return true;
    }

    function setFees(uint256 _protocolFee, uint256 _gasFee) external onlyRole(AUTHORITY_ROLE) {
        protocolFee = _protocolFee;
        gasFee = _gasFee;
    }

    /// @notice Register an insertion verifier for a specific (batchSize, treeDepth) pair.
    /// @dev Pass address(0) to clear a previously registered verifier.
    function setInsertionVerifier(
        uint256 batchSize,
        uint256 treeDepth,
        address verifier
    ) external onlyRole(AUTHORITY_ROLE) {
        insertionVerifiersByConfig[_insertionVerifierKey(batchSize, treeDepth)] = ICurvyInsertionVerifierV2(verifier);
    }

    function _insertionVerifierKey(uint256 batchSize, uint256 treeDepth) private pure returns (bytes32) {
        return keccak256(abi.encode(batchSize, treeDepth));
    }

    //#endregion

    //#region Public functions

    /// @inheritdoc ICurvyAggregatorAlpha
    function autoShield(CurvyTypes.Note memory note) external payable override {
        if (!portalFactory.portalIsRegistered(msg.sender)) revert PortalNotRegistered();

        address tokenAddress = curvyVault.getTokenAddress(note.token);

        if (tokenAddress != NATIVE_ETH) {
            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), note.amount);
            IERC20(tokenAddress).forceApprove(address(curvyVault), note.amount);
        }

        curvyVault.deposit{ value: msg.value }(tokenAddress, address(this), note.amount);

        uint256 feeAmount = (note.amount * curvyVault.depositFee()) / 10000;
        uint256 netAmount = note.amount - feeAmount;
        uint256 noteId = PoseidonT4.hash([note.ownerHash, netAmount, note.token]);

        if (noteStatus[noteId] != NoteStatus.UNKNOWN) revert NoteAlreadyKnown();
        noteStatus[noteId] = NoteStatus.PENDING;

        uint256[] memory _noteIds = new uint256[](1);
        uint256[][2] memory _ephemeralKeys;
        _ephemeralKeys[0] = new uint256[](1);
        _ephemeralKeys[1] = new uint256[](1);
        uint16[] memory _viewTags = new uint16[](1);
        uint256[] memory _tokens = new uint256[](1);
        uint256[] memory _amounts = new uint256[](1);
        bool[] memory _isPlaintext = new bool[](1);

        _noteIds[0] = noteId;
        _ephemeralKeys[0][0] = note.ephemeralKey[0];
        _ephemeralKeys[1][0] = note.ephemeralKey[1];
        _viewTags[0] = note.viewTag;
        _tokens[0] = note.token;
        _amounts[0] = netAmount;
        _isPlaintext[0] = true;

        emit PendingNotes(_noteIds, _ephemeralKeys, _viewTags, _tokens, _amounts, _isPlaintext);
    }

    /// @inheritdoc ICurvyAggregatorAlpha
    function commitPendingNotes(
        uint256 batchSize,
        uint256 treeDepth,
        uint256[] memory noteIds,
        uint256 newNotesRoot,
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c
    ) external override {
        if (noteIds.length != batchSize) revert NoteIdsLengthMismatch();

        ICurvyInsertionVerifierV2 verifier = insertionVerifiersByConfig[
            _insertionVerifierKey(batchSize, treeDepth)
        ];
        if (address(verifier) == address(0)) revert InsertionVerifierNotConfigured();

        uint256 currentRoot = _currentNotesTreeRoot;
        uint256 currentIndex = _currentNoteIndex;
        uint256 newIndex = currentIndex;

        for (uint256 i = 0; i < batchSize; i += 1) {
            uint256 noteId = noteIds[i];
            if (noteId == 0) continue;
            if (noteStatus[noteId] != NoteStatus.PENDING) revert NoteNotScheduledForDeposit();
            noteStatus[noteId] = NoteStatus.INCLUDED;
            newIndex += 1;
        }

        // Mirror circomlib MultiInputSha256: sha256 of big-endian uint256s in order
        // [noteIds..., currentRoot, newRoot, currentIndex, newIndex].
        uint256 inputHash = uint256(
            sha256(abi.encodePacked(noteIds, currentRoot, newNotesRoot, currentIndex, newIndex))
        );

        uint256[2] memory publicSignals;
        publicSignals[0] = newNotesRoot;
        publicSignals[1] = inputHash;
        if (!verifier.verifyProof(proof_a, proof_b, proof_c, publicSignals)) revert InvalidProof();

        _currentNotesTreeRoot = newNotesRoot;
        _currentNoteIndex = newIndex;
        validNotesRoot[newNotesRoot] = true;

        uint256 batchIndex = _currentNotesBatchIndex;
        emit CommittedNotes(batchIndex, noteIds);
        _currentNotesBatchIndex = batchIndex + 1;
    }

    /// @inheritdoc ICurvyAggregatorAlpha
    function submitAggregationRequest(
        CurvyTypes.OutputNote[3] memory outputNotes,
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[] memory publicInputs
    ) external override {
        // publicInputs[0] = referenced notes-tree root.
        if (!validNotesRoot[publicInputs[0]]) revert UnknownReferencedRoot();

        // publicInputs[1] = used gas fee, publicInputs[2] = used protocol fee.
        if (publicInputs[1] != gasFee || publicInputs[2] != protocolFee) revert FeeMismatch();

        uint256[] memory noteIds = new uint256[](3);
        uint16[] memory viewTags = new uint16[](3);
        uint256[] memory tokens = new uint256[](3); // encryptedTokenId
        uint256[] memory amounts = new uint256[](3); // encryptedAmount
        bool[] memory isPlaintext = new bool[](3);
        uint256[][2] memory ephemeralKeys;
        ephemeralKeys[0] = new uint256[](3);
        ephemeralKeys[1] = new uint256[](3);

        // Output-note bookkeeping: must not be known yet; flip to PENDING.
        for (uint256 i = 0; i < 3; i += 1) {
            uint256 noteId = outputNotes[i].noteId;
            if (noteId == 0) continue;
            if (noteStatus[noteId] != NoteStatus.UNKNOWN) revert NoteAlreadyKnown();
            noteStatus[noteId] = NoteStatus.PENDING;

            noteIds[i] = outputNotes[i].noteId;
            ephemeralKeys[0][i] = outputNotes[i].ephemeralKey[0];
            ephemeralKeys[1][i] = outputNotes[i].ephemeralKey[1];
            viewTags[i] = outputNotes[i].viewTag;
            tokens[i] = outputNotes[i].encryptedTokenId;
            amounts[i] = outputNotes[i].enctypedAmount;
            isPlaintext[i] = false;
        }

        // Nullifiers start after the 3 output-note blocks (5 inputs each).
        uint256 nullifierStart = 3 + 3 * 5;
        uint256 nullifierCount = publicInputs.length - nullifierStart;
        uint256[] memory nullifiers = new uint256[](nullifierCount);
        for (uint256 i = 0; i < nullifierCount; i += 1) {
            uint256 nullifier = publicInputs[nullifierStart + i];
            if (aggregationNullifiers[nullifier] || withdrawalNullifiers[nullifier])
                revert NullifierAlreadyRegistered();
            aggregationNullifiers[nullifier] = true;
            nullifiers[i] = nullifier;
        }

        if (!_mockVerify(proof_a, proof_b, proof_c, publicInputs)) revert InvalidProof();

        uint256 nullifierBatchIndex = _currentNullifiersBatchIndex;
        emit CommittedNullifiers(nullifierBatchIndex, nullifiers);
        emit PendingNotes(noteIds, ephemeralKeys, viewTags, tokens, amounts, isPlaintext);

        _currentNullifiersBatchIndex = nullifierBatchIndex + 1;
    }

    /// @inheritdoc ICurvyAggregatorAlpha
    function submitWithdrawalRequest(
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[] memory publicInputs
    ) external override {
        if (!_mockVerify(proof_a, proof_b, proof_c, publicInputs)) revert InvalidWithdrawProof();

        if (!validNotesRoot[publicInputs[0]]) revert UnknownReferencedRoot();
        if (publicInputs[3] != gasFee || publicInputs[4] != protocolFee) revert FeeMismatch();
        if (publicInputs[2] <= publicInputs[3] + publicInputs[4]) revert NetAmountNonPositive();

        // Register withdrawal nullifiers
        uint256 nullifierStart = 6;
        uint256 nullifierCount = publicInputs.length - nullifierStart;
        uint256[] memory nullifiers = new uint256[](nullifierCount);
        for (uint256 i = 0; i < nullifierCount; i += 1) {
            uint256 nullifier = publicInputs[nullifierStart + i];
            if (withdrawalNullifiers[nullifier] || aggregationNullifiers[nullifier])
                revert NullifierAlreadyRegistered();
            withdrawalNullifiers[nullifier] = true;
            nullifiers[i] = nullifier;
        }

        // Execute withdrawal transfers
        uint256 tokenId = publicInputs[5];
        uint256 usedGasFee = publicInputs[3];
        uint256 netAmount = publicInputs[2] - usedGasFee - publicInputs[4];
        if (usedGasFee > 0) {
            curvyVault.withdraw(tokenId, msg.sender, usedGasFee);
        }
        curvyVault.withdraw(tokenId, address(uint160(publicInputs[1])), netAmount);

        uint256 nullifierBatchIndex = _currentNullifiersBatchIndex;
        emit CommittedNullifiers(nullifierBatchIndex, nullifiers);
        _currentNullifiersBatchIndex = nullifierBatchIndex + 1;
    }

    /// @dev Mock verifier. Always returns true; real verifier wiring deferred to PRD-009/010 verifier work.
    function _mockVerify(
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[] memory publicInputs
    ) private pure returns (bool) {
        proof_a;
        proof_b;
        proof_c;
        publicInputs;
        return true;
    }

    //#endregion

    //#region View

    function getCurrentNotesTreeRoot() external view override returns (uint256) {
        return _currentNotesTreeRoot;
    }

    function getCurrentNotesBatchIndex() external view override returns (uint256) {
        return _currentNotesBatchIndex;
    }

    function getCurrentNullifiersBatchIndex() external view override returns (uint256) {
        return _currentNullifiersBatchIndex;
    }

    function getCurrentNoteIndex() external view override returns (uint256) {
        return _currentNoteIndex;
    }

    function getInsertionVerifier(uint256 batchSize, uint256 treeDepth) external view override returns (address) {
        return address(insertionVerifiersByConfig[_insertionVerifierKey(batchSize, treeDepth)]);
    }

    //#endregion
}
