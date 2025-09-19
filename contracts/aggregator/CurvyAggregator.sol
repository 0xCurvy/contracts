// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

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
contract CurvyAggregator
{
    function _authorizeUpgrade(address _newImplementation) internal override {}

    /// @inheritdoc ICurvyAggregator_NoAssetTransfer
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
        if (_update.csuc != address(0)) {
//            csuc = ICSUC(_update.csuc);
        }
        if (_update.feeCollector != address(0)) {
            feeCollector = _update.feeCollector;
        }

        // Note: withdrawBps = 0 is valid value
        withdrawBps = _update.withdrawBps;

        return true;
    }

    /// @inheritdoc ICurvyAggregator_NoAssetTransfer
    function wrap(CurvyAggregator_Types.Note[] memory _notes) public onlyCSUC returns (bool _success) {
        for (uint256 i; i < _notes.length; ++i) {
            // Wrapping a note with zero amount is not allowed
            if (_notes[i].amount == 0) return false;

            address _token = address(uint160(_notes[i].token));

            bytes32 _noteHash = keccak256(abi.encode(_notes[i]));
            noteInfo[_noteHash].note = _notes[i];
            noteInfo[_noteHash].deadline = block.number + CurvyAggregator_Constants.NOTE_INCLUSION_BLOCK_OFFSET;

            emit WrappingToken(_token, _notes[i].amount);
        }

        return true;
    }

    /// @inheritdoc ICurvyAggregator_NoAssetTransfer
    function processWraps(CurvyAggregator_Types.WrappingZKP memory _data) public returns (bool _success) {
        uint256 _totalNoteFields = _data.inputs.length - 2;
        for (uint256 i; i < _totalNoteFields; i += CurvyAggregator_Constants.CURVY_INSERTION_NOTE_FIELDS) {
            bytes32 _noteHash = keccak256(
                abi.encode(
                    CurvyAggregator_Types.Note({
                        ownerHash: _data.inputs[i],
                        token: _data.inputs[i + 1],
                        amount: _data.inputs[i + 2]
                    })
                )
            );

            CurvyAggregator_Types.NoteWithMetaData storage _noteWithMetadata = noteInfo[_noteHash];

            if (_noteWithMetadata.sender == address(0)) {
                continue;
            }

            require(_noteWithMetadata.deadline < block.number, "CurvyAggregator: note has been rejected yet!");
            require(_noteWithMetadata.included == false, "CurvyAggregator: note is already included!");

            _noteWithMetadata.included = true;
        }

        uint256 _oldNoteTreeRoot = _data.inputs[_data.inputs.length - 2];
        uint256 _newNoteTreeRoot = _data.inputs[_data.inputs.length - 1];

        // Check if the current state was computed over on by the circuit/proof
        require(noteTreeRoot == _oldNoteTreeRoot, "CurvyAggregator: current note tree root mismatch!");

        // check: that the proof is valid
        require(
            insertionVerifier.verifyProof(_data.a, _data.b, _data.c, _data.inputs),
            "CurvyAggregator: invalid insertion proof!"
        );

        // Update the roots of the trees
        noteTreeRoot = _newNoteTreeRoot;

        return true;
    }

    /// @inheritdoc ICurvyAggregator_NoAssetTransfer
    function operatorExecute(CurvyAggregator_Types.ActionExecutionZKP calldata _data)
    public
    onlyOperator
    returns (bool _success)
    {
        uint256 _oldNullifierTreeRoot = _data.inputs[21];
        uint256 _newNullifierTreeRoot = _data.inputs[22];
        uint256 _oldNoteTreeRoot = _data.inputs[23];
        uint256 _newNoteTreeRoot = _data.inputs[24];

        // check: if the current state was computed over on by the circuit/proof
        require(noteTreeRoot == _oldNoteTreeRoot, "CurvyAggregator: current note tree root mismatch!");
        require(nullifierTreeRoot == _oldNullifierTreeRoot, "CurvyAggregator: current nullifier tree root mismatch!");

        require(
            aggregationVerifier.verifyProof(_data.a, _data.b, _data.c, _data.inputs),
            "CurvyAggregator: invalid aggregation proof!"
        );

        // Update the roots of the trees
        noteTreeRoot = _newNoteTreeRoot;
        nullifierTreeRoot = _newNullifierTreeRoot;

        // TODO: determine if events need to be emitted here for (ephemeral keys, nullifer hashes, etc.)

        return true;
    }

    /// @inheritdoc ICurvyAggregator_NoAssetTransfer
    function collectFees(address[] memory _tokens, address _to) public onlyFeeCollector returns (bool _success) {
        revert("CurvyAggregator: collectFees is deprecated, use CSUC instead!");
    }

    /// @inheritdoc ICurvyAggregator_NoAssetTransfer
    function unwrap(CurvyAggregator_Types.UnwrappingZKP calldata _data) public nonReentrant returns (bool _success) {
        // circuit:
        // outputs:
        //      newNullifierRoot    idx = 0
        //      feeAmount           idx = 1
        // public inputs:
        //      notesTreeRoot       idx = 2
        //      oldNullifiersRoot   idx = 3
        //      withdrawnAmounts    idx = {4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
        //      destinationAddress  idx = {14, 15, 16, 17, 18, 19, 20, 21, 22, 23}
        //      nullifiersHash      idx = 24
        //      token               idx = 25
        uint256 _oldNoteTreeRoot = _data.inputs[2];
        uint256 _oldNullifierTreeRoot = _data.inputs[3];

        address[] memory _destinationAddresses = new address[](10);
        uint256[] memory _withdrawnAmounts = new uint256[](10);
        uint256 amount = 0;
        uint256 cnt = 0;
        for (uint256 i = 4; i < 14; i++) {
            if (_data.inputs[i] != 0) {
                cnt++;
            }
            _withdrawnAmounts[i - 4] = _data.inputs[i];
            amount += _data.inputs[i];
            _destinationAddresses[i - 4] = address(uint160(_data.inputs[i + 10]));
        }

        // TODO: check if ...nullifiers... need to be emitted
        uint256 _newNullifierTreeRoot = _data.inputs[0];
        address _token = address(uint160(_data.inputs[25]));
        uint256 _feeAmount = _data.inputs[1];

        // Check if the current state was computed over on by the circuit/proof
        require(noteTreeRoot == _oldNoteTreeRoot, "CurvyAggregator: current note tree root mismatch!");
        require(nullifierTreeRoot == _oldNullifierTreeRoot, "CurvyAggregator: current nullifier tree root mismatch!");

        require(
            withdrawVerifier.verifyProof(_data.a, _data.b, _data.c, _data.inputs),
            "CurvyAggregator: invalid withdraw proof!"
        );

        // Update the root of the nullifier tree
        nullifierTreeRoot = _newNullifierTreeRoot;

        // Update the fee collector's balance
        uint256 _minimumFee = (amount * withdrawBps) / CurvyAggregator_Constants.TOTAL_BASE_POINTS;
        require(_feeAmount >= _minimumFee, "CurvyAggregator: fee amount incorrectly set!");

        // Note: Aggregator holds its funds inside CSUC -> User 'withdrawal' from Aggregator
        //       happens through CSUC contract. From which they can withdraw to arbitrary address.
//        uint256 _actionId = CSUC_Constants.TRANSFER_ACTION_ID;

//        CSUC_Types.Action[] memory _actions = new CSUC_Types.Action[](cnt + 1);
//        for (uint256 i = 0; i < cnt; i++) {
//            if (_withdrawnAmounts[i] == 0) {
//                continue;
//            }
//            _actions[i].from = address(this);
//            _actions[i].payload = CSUC_Types.ActionPayload({
//                actionId: _actionId,
//                token: _token,
//                amount: _withdrawnAmounts[i],
//                totalFee: 0,
//                parameters: abi.encode(_destinationAddresses[i]),
//                limit: block.number
//            });
//        }
//        _actions[cnt].from = address(this);
//        _actions[cnt].payload = CSUC_Types.ActionPayload({
//            actionId: _actionId,
//            token: _token,
//            amount: _feeAmount,
//            totalFee: 0,
//            parameters: abi.encode(feeCollector),
//            limit: block.number
//        });

//        require(
//            ICSUC(csuc).actionHandlerCallback(_actions) == _actions.length,
//            "CurvyAggregator: CSUC action handler failed!"
//        );

        return true;
    }

    /// @inheritdoc ICurvyAggregator_NoAssetTransfer
    function withdrawRejected(bytes32 _noteHash) public nonReentrant returns (bool _success) {
        revert("CurvyAggregator: withdrawRejected is deprecated (deposits happen through CSUC)!");
    }

    /// @inheritdoc ICurvyAggregator_NoAssetTransfer
    function noteTree() public view returns (uint256 _root) {
        return noteTreeRoot;
    }

    /// @inheritdoc ICurvyAggregator_NoAssetTransfer
    function nullifierTree() public view returns (uint256 _root) {
        return nullifierTreeRoot;
    }

    /// @inheritdoc ICurvyAggregator_NoAssetTransfer
    function getNoteInfo(bytes32 _noteHash)
    external
    view
    returns (CurvyAggregator_Types.NoteWithMetaData memory _note)
    {
        return noteInfo[_noteHash];
    }

    // TODO: remove this function before mainnet deployment
    function reset() public {
        noteTreeRoot = 0;
        nullifierTreeRoot = 0;
    }

    // ------------------------------------------------------------------ Storage

    /// @notice Root of the tree containing all notes.
    uint256 noteTreeRoot;
    /// @notice Root of the tree contaiing all of the used nullifiers.
    uint256 nullifierTreeRoot;

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

    /// @notice ICSUC handle
//    ICSUC public csuc;

    /// @notice Modifier to ensure that the function can be called only by the Curvy Operator.
    modifier onlyOperator() {
        require(msg.sender == operator, "CurvyAggregator: only operator can call this function!");
        _;
    }

    /// @notice Modifier to ensure `deposits/wraps` can happen only from the CSUC contract.
    modifier onlyCSUC() {
        require(msg.sender == address(csuc), "CurvyAggregator: only CSUC can call this function!");
        _;
    }

    /// @notice Modifier to ensure that the function can be called only by the Curvy Fee Collector.
    modifier onlyFeeCollector() {
        require(msg.sender == feeCollector, "CurvyAggregator: only fee collector can call this function!");
        _;
    }
}
