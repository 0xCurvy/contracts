// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

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
contract CurvyAggregator is IERC1155TokenReceiver
{
    /// @notice Link to wrapper contract
    constructor(address payable tokenWrapperAddress) {
        tokenWrapper = MetaERC20Wrapper(tokenWrapperAddress);
    }

    event DepositedNote(uint256 noteId);
    event DepositedNotesHash(uint256 notesHash);

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

        // Note: withdrawBps = 0 is valid value
        withdrawBps = _update.withdrawBps;

        return true;
    }

    function depositNote(
        address fromAddress,
        CurvyAggregator_Types.Note memory note,
        bytes memory signature
    ) public {
        tokenWrapper.safeTransferFrom(
            fromAddress,
            address(this),
            note.token,
            note.amount,
            signature
        );

        uint256 noteId = uint256(sha256(
            abi.encodePacked([note.ownerHash, note.token, note.amount])
        )) % CurvyAggregator_Constants.SNARK_SCALAR_FIELD; // Mozda redosled ne valja

        pendingIdsQueue[noteId] = true;

        emit DepositedNote(noteId);
    }


    // depositNotes function from the CSUC (wrap)
    //     sa kojeg walleta se prebacuje i koliko i koji ownerHash se prebacuje
    //     ubacuje u niz noteova koji je pending queue

    // function depositNotes(
    //     address[] memory fromAddresses,
    //     CurvyAggregator_Types.Note[] memory _notes,
    //     bytes[] memory signatures
    // ) public onlyCSUC returns (bool _success) {
    //     for (uint i = 0; i < notes.length; i += 1) {
    //         CurvyAggregator_Types.Note[] memory note = _notes[i];

    //         // PROBABLY NOT FEASIBLE DUE TO COSTS
    //         // ====================================
    //         // tokenWrapper.metaSafeTransferFrom(
    //         //     fromAddresses[i],
    //         //     address(this),
    //         //     note.token,
    //         //     note.amount,
    //         //     false,
    //         //     signatures[i]
    //         // );

    //         bytes32 noteId = sha256(
    //             abi.encode(note.ownerHash, note.token, note.amount)
    //         ); // Mozda redosled ne valja

    //         pendingIdsQueue[noteId] = true;
    //     }
    // }
    
    // commitDepositBatch function
    //     receive proof
    //     calculate hash of notes from array
    //     check root
    //     verify proof
    //     update root (note)
    //     clear pending queue
    function commitDepositBatch(
        uint256[] memory depositedNoteIds,
        uint[] memory proof_a,
        uint[][] memory proof_b,
        uint[] memory proof_c,
        uint[] memory publicInputs
    ) public {
        uint256 num = depositedNoteIds.length;
        require(num <= MAX_PENDING, "Invalid note ids array length");

        for (uint256 i = 0; i < num; i += 1) {
            uint256 noteId = depositedNoteIds[i];
            require(pendingIdsQueue[noteId], "Note not scheduled for deposit!");
            delete pendingIdsQueue[noteId];
        }

        uint256 notesHash = uint256(sha256(abi.encodePacked(depositedNoteIds))) % CurvyAggregator_Constants.SNARK_SCALAR_FIELD;

        uint256 numPublicInputs = publicInputs.length;

        // SOME public input oldNotesTreeRoot == notesTreeRoot (require)
        require(
            notesTreeRoot == publicInputs[numPublicInputs - 3],
            "Invalid notes root"
        );

        // SOME public input notesHash == notesHash (require)
        require(
            notesHash == publicInputs[numPublicInputs - 1],
            "Notes hash missmatch"
        ); // PROVERITI INDEX

        // TODO: Verify proof
        // require(
        //     insertionVerifier.verifyProof(proof_a, proof_b, proof_c, publicInputs),
        //     "CurvyAggregator: invalid insertion proof!"
        // );

        notesTreeRoot = publicInputs[numPublicInputs - 2];
    }
    

    // commitAggregationBatch function
    //     receive proof
    //     calculate hash of nullifiers
    //     check roots
    //     verify proof
    //     update roots

    function commitAggregation(
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[46] memory publicInputs
    ) public returns (bool success) {
        // TODO: calculate hash of nullifiers

        // TODO: check indexes of publicInputs
        uint256 oldNullifiersTreeRoot = publicInputs[21];
        uint256 newNullifiersTreeRoot = publicInputs[22];
        uint256 oldNotesTreeRoot = publicInputs[23];
        uint256 newNotesTreeRoot = publicInputs[24];

        require(notesTreeRoot == oldNotesTreeRoot, "CurvyAggregator: current note tree root mismatch!");
        require(nullifiersTreeRoot == oldNullifiersTreeRoot, "CurvyAggregator: current nullifier tree root mismatch!");

        // require(
        //     aggregationVerifier.verifyProof(proof_a, proof_b, proof_c, publicInputs),
        //     "CurvyAggregator: invalid aggregation proof!"
        // );

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

    function noteTree() public view returns (uint256 _root) {
        return notesTreeRoot;
    }

    function nullifierTree() public view returns (uint256 _root) {
        return nullifiersTreeRoot;
    }

    function getNoteInfo(bytes32 _noteHash)
    external
    view
    returns (CurvyAggregator_Types.NoteWithMetaData memory _note)
    {
        return noteInfo[_noteHash];
    }

    // TODO: remove this function before mainnet deployment
    function reset() public {
        notesTreeRoot = 0;
        nullifiersTreeRoot = 0;
    }

    // ------------------------------------------------------------------ Storage
    /// @notice Maximum number of pending notes
    uint256 constant MAX_PENDING = 50;

    /// @notice Link to wrapper contract
    MetaERC20Wrapper tokenWrapper;

    /// @notice Queue of note ids waiting for deposit commitment
    mapping(uint256 => bool) pendingIdsQueue;

    /// @notice Root of the tree containing all notes.
    uint256 notesTreeRoot;
    /// @notice Root of the tree contaiing all of the used nullifiers.
    uint256 nullifiersTreeRoot;

    /// @notice Notes that are waiting to be included in the note tree / were rejected / withdraw.
    mapping(bytes32 => CurvyAggregator_Types.NoteWithMetaData) noteInfo;

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

    /// @notice Withdraw Fee computed in basis points (bps).
    /// @dev 100 bps = 1% of the amount being withdrawn.
    /// @dev Example: 0.8% fee should be set to 80 bps.
    uint256 public withdrawBps;

    /// @notice Balances of the fee collector
    /// @dev Maps token address to fee collector address to balance.
    mapping(address => mapping(address => uint256)) public feeCollectorBalancesDeprecated;

    /// @notice Modifier to ensure that the function can be called only by the Curvy Operator.
    modifier onlyOperator() {
        require(msg.sender == operator, "CurvyAggregator: only operator can call this function!");
        _;
    }

    /// @notice Modifier to ensure `deposits/wraps` can happen only from the CSUC contract.
    modifier onlyCSUC() {
//        require(msg.sender == address(csuc), "CurvyAggregator: only CSUC can call this function!");
        require(msg.sender == address(0x0), "CurvyAggregator: only CSUC can call this function!");
        _;
    }

    /// @notice Modifier to ensure that the function can be called only by the Curvy Fee Collector.
    modifier onlyFeeCollector() {
        require(msg.sender == feeCollector, "CurvyAggregator: only fee collector can call this function!");
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
