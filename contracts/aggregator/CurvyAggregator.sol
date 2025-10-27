// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;


import { ICurvyInsertionVerifier, ICurvyAggregationVerifier,  ICurvyWithdrawVerifier } from "./verifiers/ICurvyVerifiers.sol";

// TODO: Extract types away from versioned vault
import "../vault/CurvyVaultV1.sol";
import {PoseidonT4} from "./utils/PoseidonT4.sol";

/**
 * @title CurvyAggregator_NoAssetTransfer
 * @author Curvy Protocol (https://curvy.box)
 * @dev Curvy's Aggregator contract.
 */
contract CurvyAggregator
{
    struct ConfigurationUpdate {
        address insertionVerifier;
        address aggregationVerifier;
        address withdrawVerifier;
        address operator;
        address feeCollector;
        address payable curvyVault;
    }

    struct Note {
        uint256 ownerHash;
        uint256 token;
        uint256 amount;
    }

    /// @notice Link to wrapper contract
    constructor() {
        operator = msg.sender;
        feeCollector = msg.sender;
    }
    
    function _authorizeUpgrade(address _newImplementation) internal {}

    function updateConfig(ConfigurationUpdate memory _update)
    public onlyOperator
    returns (bool _success)
    {
        if (_update.insertionVerifier != address(0)) {
            insertionVerifier = ICurvyInsertionVerifier(_update.insertionVerifier);
        }
        if (_update.aggregationVerifier != address(0)) {
            aggregationVerifier = ICurvyAggregationVerifier(_update.aggregationVerifier);
        }
        if (_update.withdrawVerifier != address(0)) {
            withdrawVerifier = ICurvyWithdrawVerifier(_update.withdrawVerifier);
        }
        if (_update.operator != address(0)) {
            operator = _update.operator;
        }
        if (_update.feeCollector != address(0)) {
            feeCollector = _update.feeCollector;
        }
        if (_update.curvyVault != address(0)) {
            curvyVault = CurvyVaultV1(_update.curvyVault);
        }

        return true;
    }

    event DepositedNote(uint256 noteId);

    // depositNotes function from the CSUC (wrap)
    //     sa kojeg walleta se prebacuje i koliko i koji ownerHash se prebacuje
    //     ubacuje u niz noteova koji je pending queue

    function depositNote(
        address from,
        CurvyAggregator.Note memory note,
        bytes memory signature
    ) public {
        // TODO: Gas fee
        curvyVault.transfer(CurvyMetaTransaction(from, address(this), note.token, note.amount, 0, CurvyMetaTransactionType.Transfer), signature);

        uint256 noteId = PoseidonT4.hash([note.ownerHash, note.amount, note.token]);

        pendingIdsQueue[noteId] = true;

        emit DepositedNote(noteId);
    }

    // commitDepositBatch function
    //     receive proof
    //     calculate hash of notes from array
    //     check root
    //     verify proof
    //     update root (note)
    //     clear pending queue

    // circuit:
    // ------------20-50---------------
    // public inputs:
    //      noteIds             idx = {0, 1, ..., 50}
    //      oldNotesRoot        idx = 51
    //      newNotesRoot        idx = 52
    // ------------20-2----------------
    // public inputs:
    //      noteIds             idx = {0, 1}
    //      oldNotesRoot        idx = 2
    //      newNotesRoot        idx = 3
    // ---------------------------------
    function commitDepositBatch(
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[4] memory publicInputs
    ) public returns (bool success) {
        for (uint256 i = 0; i < MAX_PENDING; i += 1) {
            uint256 noteId = publicInputs[i];
            if (noteId != 0) {
                require(pendingIdsQueue[noteId], "Note not scheduled for deposit!");
                delete pendingIdsQueue[noteId];
            }
        }

        uint256 numPublicInputs = publicInputs.length;

        require(
            notesTreeRoot == publicInputs[numPublicInputs - 2],
            "Invalid notes root"
        );

        require(
            insertionVerifier.verifyProof(proof_a, proof_b, proof_c, publicInputs),
            "CurvyAggregator: invalid insertion proof!"
        );

        notesTreeRoot = publicInputs[numPublicInputs - 1];

        return true;
    }

    // commitAggregationBatch function
    //     receive proof
    //     calculate hash of nullifiers
    //     check roots
    //     verify proof
    //     update roots

    // circuit:
    // ------------10-10-2---------------
    // outputs:
    //      outputNoteIds       idx = {0, 1, ..., 20}
    // public inputs:
    //      oldNullifiersRoot   idx = 21
    //      newNullifiersRoot   idx = 22
    //      oldNotesRoot        idx = 23
    //      newNotesRoot        idx = 24
    //      ephemeralKeys       idx = {25, 26, ..., 44}
    //      nullifiersHash      idx = 45
    // ------------2-2-2----------------
    // outputs:
    //      outputNoteIds       idx = {0, 1, 2, 3, 4}
    // public inputs:
    //      oldNullifiersRoot   idx = 5
    //      newNullifiersRoot   idx = 6
    //      oldNotesRoot        idx = 7
    //      newNotesRoot        idx = 8
    //      ephemeralKeys       idx = {9, 10, 11, 12}
    //      nullifiersHash      idx = 13
    // ---------------------------------

    function commitAggregationBatch(
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[14] memory publicInputs
    ) public returns (bool success) {
        // uint256 oldNullifiersTreeRoot = publicInputs[21];
        // uint256 newNullifiersTreeRoot = publicInputs[22];
        // uint256 oldNotesTreeRoot = publicInputs[23];
        // uint256 newNotesTreeRoot = publicInputs[24];

        uint256 oldNullifiersTreeRoot = publicInputs[5];
        uint256 newNullifiersTreeRoot = publicInputs[6];
        uint256 oldNotesTreeRoot = publicInputs[7];
        uint256 newNotesTreeRoot = publicInputs[8];

        require(notesTreeRoot == oldNotesTreeRoot, "CurvyAggregator: current note tree root mismatch!");
        require(nullifiersTreeRoot == oldNullifiersTreeRoot, "CurvyAggregator: current nullifier tree root mismatch!");

        require(
            aggregationVerifier.verifyProof(proof_a, proof_b, proof_c, publicInputs),
            "CurvyAggregator: invalid aggregation proof!"
        );

        // Update the roots of the trees
        notesTreeRoot = newNotesTreeRoot;
        nullifiersTreeRoot = newNullifiersTreeRoot;

        return true;
    }

    // commitWithdrawBatch function
    //     receive proof
    //     calculate hash of nullifiers
    //     check roots
    //     verify proof
    //     update root (nullifier)
    //     execute transfers in batch

    // circuit:
    // ------------10-10-20---------------
    // outputs:
    //      newNullifierRoot    idx = 0
    //      feeAmount           idx = 1
    // public inputs:
    //      notesTreeRoot       idx = 2
    //      oldNullifiersRoot   idx = 3
    //      withdrawnAmounts    idx = {4, 5, ..., 13}
    //      destinationAddress  idx = {14, 15, ..., 23}
    //      nullifiersHash      idx = 24
    //      token               idx = 25
    // ------------2-2-20---------------
    // outputs:
    //      newNullifierRoot    idx = 0
    //      feeAmount           idx = 1
    // public inputs:
    //      notesTreeRoot       idx = 2
    //      oldNullifiersRoot   idx = 3
    //      withdrawnAmounts    idx = {4, 5}
    //      destinationAddress  idx = {6, 7}
    //      nullifiersHash      idx = 8
    //      token               idx = 9
    // ---------------------------------

    function commitWithdrawalBatch(
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[10] memory publicInputs
    ) public returns (bool success) {

        require(publicInputs[3] == nullifiersTreeRoot, "CurvyAggregator: current nullifier tree root mismatch!");
        require(publicInputs[2] == notesTreeRoot, "CurvyAggregator: current note tree root mismatch!");

        require(
            withdrawVerifier.verifyProof(proof_a, proof_b, proof_c, publicInputs),
            "CurvyAggregator: invalid withdraw proof!"
        );

        // Update the root of the nullifier tree
        nullifiersTreeRoot = publicInputs[0];

        // Transfer withdrawals
        for (uint256 i = 0; i < MAX_WITHDRAWALS; i += 1) {
            uint256 amount = publicInputs[4 + i];
            address destinationAddress = address(uint160(publicInputs[6 + i]));
            if (amount != 0) {
                curvyVault.transfer(
                    CurvyMetaTransaction(
                        address(this),
                        destinationAddress,
                        publicInputs[9],
                        amount,
                        0,
                        CurvyMetaTransactionType.Withdraw
                    )
                );
            }
        }

        curvyVault.transfer(
            CurvyMetaTransaction(
                address(this),
                feeCollector,
                publicInputs[9],
                publicInputs[1],
                0,
                CurvyMetaTransactionType.Withdraw
            )
        );

        return true;
    }

    function noteTree() public view returns (uint256 _root) {
        return notesTreeRoot;
    }

    function nullifierTree() public view returns (uint256 _root) {
        return nullifiersTreeRoot;
    }

    function reset(uint256 newNotesTreeRoot, uint256 newNullifiersTreeRoot) public onlyOperator {
        notesTreeRoot = newNotesTreeRoot;
        nullifiersTreeRoot = newNullifiersTreeRoot;
    }

    // ------------------------------------------------------------------ Storage
    /// @notice Maximum number of pending notes
    uint256 constant MAX_PENDING = 2;

    /// @notice Maximum number of withdrawals
    uint256 constant MAX_WITHDRAWALS = 2;

    CurvyVaultV1 public curvyVault;

    /// @notice Queue of note ids waiting for deposit commitment
    mapping(uint256 => bool) public pendingIdsQueue;

    /// @notice Root of the tree containing all notes.
    uint256 notesTreeRoot;
    /// @notice Root of the tree contaiing all of the used nullifiers.
    uint256 nullifiersTreeRoot;

    /// @notice Curvy's insertion verifier.
    ICurvyInsertionVerifier public insertionVerifier;

    /// @notice Curvy's aggregation verifier.
    ICurvyAggregationVerifier public aggregationVerifier;

    /// @notice Curvy's withdraw verifier.
    ICurvyWithdrawVerifier public withdrawVerifier;

    /// @notice Curvy Operator
    address public operator;

    /// @notice Curvy Fee Collector
    address public feeCollector;

    /// @notice Modifier to ensure that the function can be called only by the Curvy Operator.
    modifier onlyOperator() {
        require(msg.sender == operator, "CurvyAggregator: only operator can call this function!");
        _;
    }
}