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
    error InsertionVerifierNotConfigured();
    error NoteIdsLengthMismatch();
    error InvalidWithdrawProof();
    error CurrentNoteTreeRootMismatch();
    error CurrentNullifierTreeRootMismatch();
    error NullifierAlreadyRegistered();
    error UnknownReferencedRoot();
    error UnderfundedReimbursement();
    error NetAmountNonPositive();
    error FeeMismatch();

    //#endregion

    //#region Events

    // audit: deposit-batch-commit visibility for off-chain indexers and monitoring
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
    /// 1. Compute note ID (hash of [ownerHash, amount, token])
    /// 2. Add note to pending queue (status PENDING)
    /// 3. Emit PendingNotes event
    function autoShield(CurvyTypes.Note memory note) external payable;

    /// @notice Commit a batch of pending notes into the notes-tree root.
    /// 1. Resolve insertion verifier for (batchSize, treeDepth)
    /// 2. Verify notes are in pending queue (status PENDING); count non-zero ids
    /// 3. Recompute circuit `inputHash` = sha256(noteIds || currentRoot || newRoot || currentIndex || newIndex)
    /// 4. Verify proof with public inputs [newNotesRoot, inputHash]
    /// 5. Flip PENDING -> INCLUDED; update root + note index; anchor validNotesRoot
    /// 6. Emit CommittedNotes
    function commitPendingNotes(
        uint256 batchSize,
        uint256 treeDepth,
        uint256[] memory noteIds,
        uint256 newNotesRoot,
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c
    ) external;

    /// @notice Submit an aggregation request producing up to 3 output notes.
    /// 1. Verify output notes are not in the pending queue (status UNKNOWN)
    /// 2. Verify referenced notes-tree root is valid
    /// 3. Verify nullifiers are not in the aggregationNullifiers mapping
    /// 4. Verify gas + protocol fees in publicInputs match contract config
    /// 5. Verify proof
    /// 6. Set all output notes PENDING
    /// 7. Register nullifiers
    /// 8. Emit CommittedNullifiers + PendingNotes
    /// 9. Bump batch indices
    function submitAggregationRequest(
        CurvyTypes.OutputNote[3] memory outputNotes,
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[] memory publicInputs
    ) external;

    /// @notice Submit a single-withdrawal request.
    /// 1. Verify nullifiers are not in the withdrawalNullifiers mapping
    /// 2. Verify gas + protocol fees in publicInputs match contract config
    /// 3. Verify proof
    /// 4. Take gas reimbursement from withdrawal amount, transfer to msg.sender via Vault
    /// 5. Transfer remaining (net) amount to destination via Vault
    /// 6. Register nullifiers
    /// 7. Emit CommittedNullifiers + Withdrawal
    /// 8. Bump nullifiers batch index
    function submitWithdrawalRequest(
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[] memory publicInputs
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
    function getInsertionVerifier(uint256 batchSize, uint256 treeDepth) external view returns (address);

    //#endregion

    /*

    // Withdrawal publicInputs layout (draft, finalized in mod-spec):
    // - 0: referenced notes-tree root (must be in validNotesRoot)
    // - 1: destination address (as uint256)
    // - 2: withdrawal amount
    // - 3: used gas fee amount (cap)
    // - 4: used protocol fee amount
    // - 5: token ID
    // - 6+: nullifiers[i]

    // aggregationPublicInputs:
    // - 0: some previously used notes tree root
    // - 1: used currentCommittedNoteIndex
    // - 2: used gas fee amount
    // - 3: used protocol fee amount
    // - 4: outputNotes[3 + (i)].noteId
    // - 5: outputNotes[3 + (i+1)].encryptedAmount
    // - 6: outputNotes[3 + (i+2)].encryptedTokenId
    // - 7: outputNotes[3 + (i+3)].ephemeralKey[0]
    // - 8: outputNotes[3 + (i+4)].ephemeralKey[1]
    // - 9: outputNotes[3 + (i+5)].viewTag
    // - 10: nullifiers[i].nullifier
    // ... 


OutputNote
    uint256 noteId
    uint256 enctypedAmount
    uint256 encryptedTokenId
    uint256[] ephemeralKey // [x, y]
    uint16 viewTag

     uint256currentNotesTreeRoot

     enum NoteStatus {
        UNKNOWN,
        PENDING,
        INCLUDED
     }

     uint256 currentNotesBatchIndex = 0;
     uint256 currentCommittedNoteIndex = 0;
     uint256 currentNullifiersBatchIndex = 0;

     // 0x123467 => true, if 0x1234567 was at some point valid root
     mapping (uint256 => boolean) notesTreeRoots

     // 0x123467 => UNKNOWN, if note with ID = 0x1234567 was never seen before
     // 0x123467 => PENDING, if note with ID = 0x1234567 was scheduled for commitment
     // 0x123467 => INCLUDED, if note with ID = 0x1234567 was committed

     mapping (uint256 => NoteStatus) pendingQueue

     // 0x123467 => true, if 0x1234567 is a registered spent nullifier
     mapping (uint256 => boolean) nullifiers



     */
}
