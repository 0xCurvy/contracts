// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

import {CurvyTypes} from "../utils/Types.sol";

interface ICurvyAggregatorAlpha {
    //#region Errors

    error PortalNotRegistered();
    error NoteNotScheduledForDeposit();
    error InvalidNotesRoot();
    error InvalidProof();
    error CurrentNoteTreeRootMismatch();
    error CurrentNullifierTreeRootMismatch();
    error InvalidWithdrawProof();

    // audit: deposit-batch-commit visibility for off-chain indexers and monitoring
    event PendingNotes(uint256[] noteIds, uint256[][2] ephemeralKeys, uint16[] viewTags, uint256[] tokens, uint256[] amounts, bool[] isPlaintext);
    event CommittedNotes(uint256 indexed batchIndex, uint256[] noteIds);
    event CommittedNullifiers(uint256 indexed batchIndex, uint256[] nullifiers);

    //#endregion

    //#region Public functions

    function autoShield(CurvyTypes.Note memory note) external payable;
    // 1. Compute note ID (hash of [ownerHash, amount, token])
    // 2. Add note to pending queue (status PENDING)
    // 3. Emit PendingNotes event
    // DA LI JE EXTERNAL?

    function commitPendingNotes(uint256[] memory noteIds) external;
    // 1. Verify notes are in pending queue (status PENDING)
    // 2. In circuit: 
    //    - compute new root based on the current notes tree root and the new note IDs
    // 3. Update current notes tree root
    // 4. Set all notes in the batch to included (status INCLUDED)
    // 5. Add new root to the notesTreeRoots mapping
    // 6. Emit CommittedNotes event

    function submitAggregationRequest(
        CurvyTypes.OutputNote[3] memory outputNotes,
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[???] memory publicInputs
    ) external;
    // 1. Verify output notes are not in the pending queue (status UNKNOWN)
    // 2. Verify that used notes tree root is valid (existing in notesTreeRoots mapping)
    // 3. For each nullifier check that it is not in the nullifiers mapping
    // 4. Verify that used gas and protocol fees set in public inputs match those set in contract
    // 5. Verify proof
    // 6. Set all output notes to pending (status PENDING)
    // 7. Add new nullifiers to the nullifiers mapping
    // 8. Emit CommittedNullifiers event
    // 9. Emit PendingNotes event
    // 10. Update current notes batch index
    // 11. Update current nullifiers batch index

    function submitWithdrawalRequest(
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[???] memory publicInputs
    ) external;
    // 1. Verify nullifiers are not in the nullifiers mapping
    // 2. Verify used gas and protocol fees set in public inputs match those set in contract
    // 2. Verify proof
    // 3. Take gas fee from the amount and transfer to message sender's Vault account
    // 4. Transfer the remaining amount to the destination address in Vault account
    // 5. Add nullifiers to the nullifiers mapping
    // 6. Emit CommittedNullifiers event
    // 7. Update current nullifiers batch index
    
    //#endregion



    /**

    // Gas costs per token?
    // Protocol fees?

    // withdrawal publicInputs:
    // - 0: some previously used notes tree root
    // - 1: destination address
    // - 2: withdrawal amoun
    // - 3: used gas fee amount
    // - 4: used protocol fee amount
    // - 5: withdrawal amount
    // - 6: token ID
    // - 7+: nullifiers[i].nullifier
    // ... 

    // aggregationPublicInputs:
    // - 0: some previously used notes tree root
    // - 1: used gas fee amount
    // - 2: used protocol fee amount
    // - 3: outputNotes[3 + (i)].noteId
    // - 4: outputNotes[3 + (i+1)].encryptedAmount
    // - 5: outputNotes[3 + (i+2)].encryptedTokenId
    // - 6: outputNotes[3 + (i+3)].ephemeralKey[0]
    // - 7: outputNotes[3 + (i+4)].ephemeralKey[1]
    // - 8: outputNotes[3 + (i+5)].viewTag
    // - 9: nullifiers[i].nullifier
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
