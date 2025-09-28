// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {PoseidonT4} from "./utils/PoseidonT4.sol";

import {MetaERC20Wrapper} from "../wrapper/MetaERC20Wrapper.sol";
import {IERC1155TokenReceiver} from "../interfaces/IERC1155TokenReceiver.sol";

import {
ICurvyInsertionVerifier,
ICurvyAggregationVerifier,
ICurvyWithdrawVerifier
} from "../interfaces/ICurvyVerifiers.sol";

import {CurvyAggregator_Types} from "./utils/_Types.sol";
import {CurvyAggregator_Constants} from "./utils/_Constants.sol";

/**
 * @title CurvyAggregator_NoAssetTransfer
 * @author Curvy Protocol (https://curvy.box)
 * @dev Curvy's Aggregator contract.
 */
/// @custom:oz-upgrades-from CurvyAggregator_NoAssetTransfer
contract CurvyAggregator is IERC1155TokenReceiver
{
    /// @notice Link to wrapper contract
    constructor(address payable tokenWrapperAddress) {
        tokenWrapper = MetaERC20Wrapper(tokenWrapperAddress);
        operator = msg.sender;
        feeCollector = msg.sender;
    }
    
    function _authorizeUpgrade(address _newImplementation) internal {}

    function updateConfig(CurvyAggregator_Types.ConfigurationUpdate memory _update)
    public
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

        return true;
    }

    event DepositedNote(uint256 noteId);
    event DepositedNotesHash(uint256 notesHash);

    // depositNotes function from the CSUC (wrap)
    //     sa kojeg walleta se prebacuje i koliko i koji ownerHash se prebacuje
    //     ubacuje u niz noteova koji je pending queue

    function depositNote(
        address fromAddress,
        CurvyAggregator_Types.Note memory note
        // bytes memory signature
    ) public {
        tokenWrapper.safeTransferFrom(
            fromAddress,
            address(this),
            note.token,
            note.amount,
            // TODO: Dodati potpis da verifikumemo za metaSafeTransaferFrom
            new bytes(0) // signature
        );

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
    // ------------20-3----------------
    // public inputs:
    //      noteIds             idx = {0, 1, 2}
    //      oldNotesRoot        idx = 3
    //      newNotesRoot        idx = 4
    // ---------------------------------
    function commitDepositBatch(
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[5] memory publicInputs
    ) public returns (bool success) {
        for (uint256 i = 0; i < MAX_PENDING; i += 1) {
            uint256 noteId = publicInputs[i];
            if (noteId != 0) {
                require(pendingIdsQueue[noteId], "Note not scheduled for deposit!");
                delete pendingIdsQueue[noteId];
            }
        }

        uint256 numPublicInputs = publicInputs.length;

        // SOME public input oldNotesTreeRoot == notesTreeRoot (require)
        require(
            notesTreeRoot == publicInputs[numPublicInputs - 2],
            "Invalid notes root"
        );

        // TODO: Verify proof
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
    //      outputNoteIds       idx = {0, 1, 2, 3, 4, 5}
    // public inputs:
    //      oldNullifiersRoot   idx = 6
    //      newNullifiersRoot   idx = 7
    //      oldNotesRoot        idx = 8
    //      newNotesRoot        idx = 9
    //      ephemeralKeys       idx = {10, 11, 12, 13}
    //      nullifiersHash      idx = 14
    // ---------------------------------

    function commitAggregationBatch(
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[14] memory publicInputs
    ) public returns (bool success) {
        // TODO: check indexes of publicInputs
        // uint256 oldNullifiersTreeRoot = publicInputs[21];
        // uint256 newNullifiersTreeRoot = publicInputs[22];
        // uint256 oldNotesTreeRoot = publicInputs[23];
        // uint256 newNotesTreeRoot = publicInputs[24];

        uint256 oldNullifiersTreeRoot = publicInputs[6];
        uint256 newNullifiersTreeRoot = publicInputs[7];
        uint256 oldNotesTreeRoot = publicInputs[8];
        uint256 newNotesTreeRoot = publicInputs[9];

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
        uint256[10] memory publicInputs // Bilo 26
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
                tokenWrapper.safeTransferFrom(
                    address(this),
                    destinationAddress,
                    publicInputs[9],
                    amount,
                    new bytes(0)
                );
            }
        }

        // Transfer fee
        tokenWrapper.safeTransferFrom(
            address(this),
            feeCollector,
            publicInputs[9],
            publicInputs[1],
            new bytes(0)
        );

        return true;
    }

    function noteTree() public view returns (uint256 _root) {
        return notesTreeRoot;
    }

    function nullifierTree() public view returns (uint256 _root) {
        return nullifiersTreeRoot;
    }

    // TODO: remove this function before mainnet deployment
    function reset() public {
        notesTreeRoot = 0;
        nullifiersTreeRoot = 0;
    }

    // ------------------------------------------------------------------ Storage
    /// @notice Maximum number of pending notes
    uint256 constant MAX_PENDING = 3;

    /// @notice Maximum number of withdrawals
    uint256 constant MAX_WITHDRAWALS = 2;

    /// @notice Link to wrapper contract
    MetaERC20Wrapper public tokenWrapper;

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

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external pure returns (bytes4) {
        return CurvyAggregator_Constants.ERC1155_RECEIVED_VALUE;
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external pure returns (bytes4) {
        return CurvyAggregator_Constants.ERC1155_BATCH_RECEIVED_VALUE;
    }
}