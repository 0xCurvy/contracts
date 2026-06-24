// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

import { CurvyTypes } from "../utils/Types.sol";

interface ICurvyAggregatorAlpha {
    //#region Enums

    enum NoteStatus {
        UNKNOWN,
        PENDING,
        INCLUDED
    }

    //#endregion

    //#region Errors

    error PortalNotRegistered();
    error NoteNotScheduledForDeposit();
    error NoteAlreadyKnown();
    error InvalidNotesRoot();
    error InvalidProof();
    error InvalidInputHash();
    error PendingNotesCommitmentVerifierNotConfigured();
    error AggregationVerifierNotConfigured();
    error WithdrawalVerifierNotConfigured();
    error NoteIdsLengthMismatch();
    error PublicSignalsLengthMismatch();
    error InvalidWithdrawProof();
    error CurrentNoteTreeRootMismatch();
    error CurrentNullifierTreeRootMismatch();
    error NullifierAlreadyRegistered();
    error UnknownReferencedRoot();
    error UnderfundedReimbursement();
    error NetAmountNonPositive();
    error FeeMismatch();
    error FeeNotePublicKeyMismatch();
    error UnsupportedAggregationConfig();
    error UnsupportedWithdrawalConfig();
    error InvalidProtocolFee();

    //#endregion

    //#region Events

    event PendingNotes(
        uint256[] noteIds,
        uint256[][2] ephemeralKeys,
        uint16[] viewTags,
        uint256[] tokens,
        uint256[] amounts,
        bool[] isPlaintext
    );
    event CommittedNotes(uint256 indexed batchIndex, uint256[] noteIds);
    event CommittedNullifiers(uint256 indexed batchIndex, uint256[] nullifiers);

    //#endregion

    //#region Public functions

    /// @notice Schedule a deposit-sourced note for inclusion.
    function autoShield(CurvyTypes.Note memory note) external payable;

    /// @notice Commit a batch of pending notes into the notes-tree root.
    /// Verifier expects single public signal `inputHash`; contract recomputes it
    /// from caller-provided `noteIds`, tracked `currentRoot`/`currentIndex`, and
    /// caller-provided `newNotesRoot`, then reduces mod the BN254 scalar field:
    ///   inputHash = sha256(noteIds || currentRoot || newRoot || currentIndex || newIndex) mod r
    function commitPendingNotes(
        uint256 batchSize,
        uint256 treeDepth,
        uint256[] memory noteIds,
        uint256 newNotesRoot,
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c
    ) external;

    /// @notice Submit a single-aggregation request (NoHashing variant).
    /// Hardcoded to maxOutputs=3, treeDepth=30. `maxInputs` selects the verifier.
    /// publicSignals layout (length = maxInputs + (3+1) + (3+1)*5 + 5):
    ///   [0..maxInputs-1]                  nullifiers
    ///   [maxInputs..maxInputs+3]          outputNoteIds (last entry = fee-note id; committed later)
    ///   [maxInputs+4 + i*5 .. +4]         encryptedNoteData[i] for i in 0..3
    ///                                     (i=3 is fee note; 5 sigs each:
    ///                                      encryptedAmount, encryptedToken,
    ///                                      ephemeralKey[0], ephemeralKey[1], viewTag)
    ///   [maxInputs+24]                    notesRoot
    ///   [maxInputs+25]                    protocolFeePerThousand
    ///   [maxInputs+26]                    gasFee
    ///   [maxInputs+27..maxInputs+28]      feeNotePublicKey[0..1]
    function submitAggregationRequest(
        uint256 maxInputs,
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[] memory publicSignals
    ) external;

    /// @notice Submit a single-withdrawal request (NoHashing variant).
    /// Hardcoded to treeDepth=30. `maxInputs` selects the verifier.
    /// publicSignals layout (length = 1 + maxInputs + 3):
    ///   [0]                               withdrawnAmount
    ///   [1..maxInputs]                    nullifiers
    ///   [maxInputs+1]                     notesRoot
    ///   [maxInputs+2]                     destinationAddress
    ///   [maxInputs+3]                     tokenId
    /// Fees are taken on-contract: usedGasFee = stored `gasFee`,
    /// protocolFeeAmount = withdrawnAmount * protocolFeePerThousand / 1000.
    function submitWithdrawalRequest(
        uint256 maxInputs,
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[] memory publicSignals
    ) external;

    //#endregion

    //#region View functions

    function noteStatus(uint256 noteId) external view returns (NoteStatus);
    function validNotesRoot(uint256 root) external view returns (bool);
    function aggregationNullifiers(uint256 nullifier) external view returns (bool);
    function withdrawalNullifiers(uint256 nullifier) external view returns (bool);
    function getCurrentNotesTreeRoot() external view returns (uint256);
    function getCurrentNotesBatchIndex() external view returns (uint256);
    function getCurrentNullifiersBatchIndex() external view returns (uint256);
    function getCurrentNoteIndex() external view returns (uint256);
    function getAggregationVerifier(
        uint256 maxInputs,
        uint256 maxOutputs,
        uint256 treeDepth
    ) external view returns (address);
    function getWithdrawalVerifier(uint256 maxInputs, uint256 treeDepth) external view returns (address);

    //#endregion
}
