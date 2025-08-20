// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ReentrancyGuardWithInitializer} from "../utils/ReentrancyGuardWithInitializer.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICSUC, CSUC_Constants} from "../csuc/Exports.sol";

import {ICurvyAggregator} from "./interface/ICurvyAggregator.sol";

import {
    ICurvyInsertionVerifier,
    ICurvyAggregationVerifier,
    ICurvyWithdrawVerifier
} from "./verifiers/v0/interface/ICurvyVerifiers.sol";

import {CurvyAggregator_Types} from "./utils/_Types.sol";
import {CurvyAggregator_Constants} from "./utils/_Constants.sol";

/**
 * @title CurvyAggregator
 * @author Curvy Protocol (https://curvy.box)
 * @dev Curvy's Aggregator contract.
 */
contract CurvyAggregator is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardWithInitializer,
    ICurvyAggregator
{
    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuardWithInitializer_init();
    }

    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}

    /// @inheritdoc ICurvyAggregator
    function updateConfig(CurvyAggregator_Types.ConfigurationUpdate memory _update)
        public
        onlyOwner
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
            csuc = ICSUC(_update.csuc);
        }
        return true;
    }

    /// @inheritdoc ICurvyAggregator
    function wrapNative(CurvyAggregator_Types.Note[] memory _notes) public payable onlyCSUC returns (bool _success) {
        uint256 _totalAmount;
        for (uint256 i; i < _notes.length; ++i) {
            require(_notes[i].amount != 0, "CurvyAggregator: wrapping 0 value not allowed!");
            address _token = address(uint160(_notes[i].token));
            require(_token == CurvyAggregator_Constants.NATIVE_TOKEN, "CurvyAggregator: token id mismatch!");

            bytes32 _noteHash = keccak256(abi.encode(_notes[i]));
            noteInfo[_noteHash].note = _notes[i];
            noteInfo[_noteHash].deadline = block.number + CurvyAggregator_Constants.NOTE_INCLUSION_BLOCK_OFFSET;
            _totalAmount += _notes[i].amount;

            emit WrappingToken(_token, _notes[i].amount);
        }

        require(msg.value == _totalAmount, "CurvyAggregator: msg.value != sum(amounts)!");

        return true;
    }

    /// @inheritdoc ICurvyAggregator
    function wrapERC20(CurvyAggregator_Types.Note[] memory _notes) public onlyCSUC returns (bool _success) {
        for (uint256 i; i < _notes.length; ++i) {
            bytes32 _noteHash = keccak256(abi.encode(_notes[i]));
            noteInfo[_noteHash].note = _notes[i];
            noteInfo[_noteHash].deadline = block.number + CurvyAggregator_Constants.NOTE_INCLUSION_BLOCK_OFFSET;

            address _token = address(uint160(_notes[i].token));
            uint256 _amount = _notes[i].amount;

            require(_amount != 0, "CurvyAggregator: wrapping 0 value not allowed!");

            uint256 _totalBefore = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
            uint256 _totalAfter = IERC20(_token).balanceOf(address(this));
            require(_totalAfter - _totalBefore == _amount, "CurvyAggregator: ERC20 transfer failed!");

            emit WrappingToken(_token, _amount);
        }

        return true;
    }

    /// @inheritdoc ICurvyAggregator
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

    /// @inheritdoc ICurvyAggregator
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

    /// @inheritdoc ICurvyAggregator
    function collectFees(address[] memory _tokens, address _to) public onlyFeeCollector returns (bool _success) {
        for (uint256 i = 0; i < _tokens.length; ++i) {
            address _token = _tokens[i];
            uint256 _balance = feeCollectorBalances[_token][feeCollector];
            require(_balance > 0, "CurvyAggregator: no fees to collect!");

            // Reset the balance after collecting
            feeCollectorBalances[_token][feeCollector] = 0;

            if (_token == CurvyAggregator_Constants.NATIVE_TOKEN) {
                (_success,) = _to.call{value: _balance}("");
                require(_success, "CurvyAggregator: native transfer failed!");
            } else {
                IERC20(_token).safeTransfer(_to, _balance);
            }
        }
        return true;
    }

    /// @inheritdoc ICurvyAggregator
    function unwrap(CurvyAggregator_Types.UnwrappingZKP calldata _data) public nonReentrant returns (bool _success) {
        uint256 _oldNoteTreeRoot = _data.inputs[_data.inputs.length - 4];
        uint256 _oldNullifierTreeRoot = _data.inputs[_data.inputs.length - 3];

        address _to = address(uint160(_data.inputs[_data.inputs.length - 2]));

        bool _withdrawFlag = _data.inputs[_data.inputs.length - 1] == 0;
        uint256 _amount = _data.inputs[0];

        // TODO: check if ...nullifiers... need to be emitted
        uint256 _inputLength = _data.inputs.length;
        uint256 _newNullifierTreeRoot = _data.inputs[_inputLength - 7];
        address _token = address(uint160(_data.inputs[_inputLength - 6]));
        uint256 _feeAmount = _data.inputs[_inputLength - 5];

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
        uint256 _minimumFee = (_amount * withdrawBps) / CurvyAggregator_Constants.TOTAL_BASE_POINTS;
        require(_feeAmount < _minimumFee, "CurvyAggregator: fee amount incorrectly set!");
        feeCollectorBalances[_token][feeCollector] += _feeAmount;

        // withdraw to CSUC, and add the funds to `_to` address
        if (_withdrawFlag == true) {
            if (_token == CurvyAggregator_Constants.NATIVE_TOKEN) {
                // User wants to withdraw to CSUC - native token
                ICSUC(csuc).wrapNative{value: _amount}(_to);
            } else {
                // User wants to withdraw to CSUC - ERC20 token
                IERC20(_token).safeIncreaseAllowance(address(csuc), _amount);
                ICSUC(csuc).wrapERC20(_to, _token, _amount);
                IERC20(_token).safeDecreaseAllowance(address(csuc), 0);
            }
        } else {
            // Handle the case if the User wants to withdraw to their own address
            if (_token == CurvyAggregator_Constants.NATIVE_TOKEN) {
                // Regular native transfer to the User's desired address
                (_success,) = _to.call{value: _amount}("");
                require(_success, "CurvyAggregator: native transfer failed!");
            } else {
                // Regular ERC20 transfer to the User's desired address
                IERC20(_token).safeTransfer(_to, _amount);
            }
        }

        return true;
    }

    /// @inheritdoc ICurvyAggregator
    function withdrawRejected(bytes32 _noteHash) public nonReentrant returns (bool _success) {
        CurvyAggregator_Types.NoteWithMetaData storage _noteWithMetadata = noteInfo[_noteHash];

        require(_noteWithMetadata.included == false, "CurvyAggregator: note is already included!");
        require(_noteWithMetadata.deadline < block.number, "CurvyAggregator: note is not rejected yet!");
        require(_noteWithMetadata.cancelled == false, "CurvyAggregator: note is already cancelled!");

        _noteWithMetadata.cancelled = true;
        address _sender = _noteWithMetadata.sender;
        address _token = address(uint160(_noteWithMetadata.note.token));
        uint256 _amount = _noteWithMetadata.note.amount;

        if (_token == CurvyAggregator_Constants.NATIVE_TOKEN) {
            (_success,) = _sender.call{value: _amount}("");
            require(_success, "CurvyAggregator: native transfer failed!");
        } else {
            IERC20(_token).safeTransfer(_sender, _amount);
        }

        return true;
    }

    /// @inheritdoc ICurvyAggregator
    function noteTree() public view returns (uint256 _root) {
        return noteTreeRoot;
    }

    /// @inheritdoc ICurvyAggregator
    function nullifierTree() public view returns (uint256 _root) {
        return nullifierTreeRoot;
    }

    /// @inheritdoc ICurvyAggregator
    function getNoteInfo(bytes32 _noteHash)
        external
        view
        returns (CurvyAggregator_Types.NoteWithMetaData memory _note)
    {
        return noteInfo[_noteHash];
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
    mapping(address => mapping(address => uint256)) public feeCollectorBalances;

    /// @notice ICSUC handle
    ICSUC public csuc;

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

    using SafeERC20 for IERC20;
}
