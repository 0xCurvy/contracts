// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "../portal/IPortalFactory.sol";
import {
ICurvyInsertionVerifier,
ICurvyAggregationVerifier,
ICurvyWithdrawVerifier
} from "./verifiers/ICurvyVerifiersAlpha.sol";
import {CurvyTypes} from "../utils/Types.sol";
import {ICurvyAggregatorAlpha} from "./ICurvyAggregatorAlpha.sol";

import {ICurvyVault} from "../vault/ICurvyVault.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PoseidonT4} from "./utils/PoseidonT4.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title CurvyAggregator
 * @author Curvy Protocol (https://curvy.box)
 * @dev Curvy's Aggregator contract.
 */
contract CurvyAggregatorAlphaV4 is ICurvyAggregatorAlpha, Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    //#region Events

    event DepositedNote(uint256 noteId);

    //#endregion

    address constant NATIVE_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    //#region State variables

    // Maximum number of notes to commit in deposit
    uint256 public maxDeposits;
    // Maximum number of aggregations
    uint256 public maxAggregations;
    // Maximum number of withdrawals
    uint256 public maxWithdrawals;

    // Queue of note ids waiting for deposit commitment
    mapping(uint256 => bool) private _pendingIdsQueue;

    // Root of the tree containing all notes.
    uint256 private _notesTreeRoot;
    // Root of the tree contaiing all of the used nullifiers.
    uint256 private _nullifiersTreeRoot;

    // Curvy's vault contract
    ICurvyVault public curvyVault;

    // Curvy's portal factory contract;
    IPortalFactory public portalFactory;

    //Curvy's insertion verifier.
    ICurvyInsertionVerifier public insertionVerifier;
    //Curvy's aggregation verifier.
    ICurvyAggregationVerifier public aggregationVerifier;
    //Curvy's withdraw verifier.
    ICurvyWithdrawVerifier public withdrawVerifier;

    //#endregion

    //#region Init functions

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    //#endregion

    //#region Owner functions

    function updateConfig(CurvyTypes.AggregatorConfigurationUpdate memory _update) external onlyOwner returns (bool) {
        if (_update.insertionVerifier != address(0)) {
            insertionVerifier = ICurvyInsertionVerifier(_update.insertionVerifier);
        }
        if (_update.aggregationVerifier != address(0)) {
            aggregationVerifier = ICurvyAggregationVerifier(_update.aggregationVerifier);
        }
        if (_update.withdrawVerifier != address(0)) {
            withdrawVerifier = ICurvyWithdrawVerifier(_update.withdrawVerifier);
        }
        if (_update.curvyVault != address(0)) {
            curvyVault = ICurvyVault(_update.curvyVault);
        }
        if (_update.portalFactory != address(0)) {
            portalFactory = IPortalFactory(_update.portalFactory);
        }
        if (_update.maxDeposits != 0) {
            maxDeposits = _update.maxDeposits;
        }
        if (_update.maxAggregations != 0) {
            maxAggregations = _update.maxAggregations;
        }
        if (_update.maxWithdrawals != 0) {
            maxWithdrawals = _update.maxWithdrawals;
        }

        return true;
    }

    function reset(uint256 newNotesTreeRoot, uint256 newNullifiersTreeRoot) external onlyOwner {
        _notesTreeRoot = newNotesTreeRoot;
        _nullifiersTreeRoot = newNullifiersTreeRoot;
    }

    //#endregions

    //#region Public functions

    function autoShield(CurvyTypes.Note memory note, address tokenAddress) external payable {
        // Only allow auto shielding of portals that were deployed through the portalFactory
        require(portalFactory.portalIsRegistered(msg.sender));

        if (tokenAddress != address(0) && tokenAddress != NATIVE_ETH) {
            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), note.amount);
            IERC20(tokenAddress).forceApprove(address(curvyVault), note.amount);
        }

        curvyVault.deposit{ value: msg.value }(tokenAddress, address(this), note.amount, 0);

        uint256 noteId = PoseidonT4.hash([note.ownerHash, note.amount, note.token]);

        _pendingIdsQueue[noteId] = true;

        emit DepositedNote(noteId);
    }

    function depositNote(address from, CurvyTypes.Note memory note, bytes memory signature) public {
        // TODO: Gas fee
        curvyVault.transfer(
            CurvyTypes.MetaTransaction(
                from,
                address(this),
                note.token,
                note.amount,
                0,
                CurvyTypes.MetaTransactionType.Transfer
            ),
            signature
        );

        uint256 noteId = PoseidonT4.hash([note.ownerHash, note.amount, note.token]);

        _pendingIdsQueue[noteId] = true;

        emit DepositedNote(noteId);
    }

    function commitDepositBatch(
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[4] memory publicInputs
    ) public returns (bool success) {
        for (uint256 i = 0; i < maxDeposits; i += 1) {
            uint256 noteId = publicInputs[i];
            if (noteId != 0) {
                require(
                    _pendingIdsQueue[noteId],
                    "CurvyAggregator#commitDepositBatch: Note not scheduled for deposit!"
                );
                delete _pendingIdsQueue[noteId];
            }
        }

        uint256 numPublicInputs = publicInputs.length;

        require(
            _notesTreeRoot == publicInputs[numPublicInputs - 2],
            "CurvyAggregator#commitDepositBatch: Invalid notes root!"
        );

        require(
            insertionVerifier.verifyProof(proof_a, proof_b, proof_c, publicInputs),
            "CurvyAggregator#commitDepositBatch: Invalid proof!"
        );

        _notesTreeRoot = publicInputs[numPublicInputs - 1];

        return true;
    }

    function commitAggregationBatch(
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[14] memory publicInputs
    ) public returns (bool) {
        uint256 oldNullifiersTreeRoot = publicInputs[2 * maxAggregations + 1];
        uint256 newNullifiersTreeRoot = publicInputs[2 * maxAggregations + 2];
        uint256 oldNotesTreeRoot = publicInputs[2 * maxAggregations + 3];
        uint256 newNotesTreeRoot = publicInputs[2 * maxAggregations + 4];

        require(
            _notesTreeRoot == oldNotesTreeRoot,
            "CurvyAggregator#commitAggregationBatch: Current note tree root mismatch!"
        );
        require(
            _nullifiersTreeRoot == oldNullifiersTreeRoot,
            "CurvyAggregator#commitAggregationBatch: Current nullifier tree root mismatch!"
        );

        require(
            aggregationVerifier.verifyProof(proof_a, proof_b, proof_c, publicInputs),
            "CurvyAggregator#commitAggregationBatch: Invalid proof!"
        );

        // Update the roots of the trees
        _notesTreeRoot = newNotesTreeRoot;
        _nullifiersTreeRoot = newNullifiersTreeRoot;

        return true;
    }

    function commitWithdrawalBatch(
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[10] memory publicInputs
    ) public returns (bool) {
        require(
            publicInputs[3] == _nullifiersTreeRoot,
            "CurvyAggregator#commitWithdrawalBatch: Current nullifier tree root mismatch!"
        );
        require(
            publicInputs[2] == _notesTreeRoot,
            "CurvyAggregator#commitWithdrawalBatch: Current note tree root mismatch!"
        );

        require(
            withdrawVerifier.verifyProof(proof_a, proof_b, proof_c, publicInputs),
            "CurvyAggregator#commitWithdrawalBatch: Invalid withdraw proof!"
        );

        // Update the root of the nullifier tree
        _nullifiersTreeRoot = publicInputs[0];

        uint256 numPublicInputs = publicInputs.length;

        // Transfer withdrawals
        for (uint256 i = 0; i < maxWithdrawals; i += 1) {
            uint256 amount = publicInputs[4 + i];
            address destinationAddress = address(uint160(publicInputs[4 + maxWithdrawals + i]));
            if (amount != 0) {
                curvyVault.transfer(
                    CurvyTypes.MetaTransaction(
                        address(this),
                        destinationAddress,
                        publicInputs[numPublicInputs - 1],
                        amount,
                        0,
                        CurvyTypes.MetaTransactionType.Transfer
                    )
                );
            }
        }

        // Fee collection
        curvyVault.transfer(
            CurvyTypes.MetaTransaction(
                address(this),
                owner(),
                publicInputs[numPublicInputs - 1],
                publicInputs[1],
                0,
                CurvyTypes.MetaTransactionType.Transfer
            )
        );

        return true;
    }

    //#endregion

    //#region View functions

    function getNoteTreeRoot() external view returns (uint256) {
        return _notesTreeRoot;
    }

    function getNullifierTreeRoot() external view returns (uint256) {
        return _nullifiersTreeRoot;
    }

    function noteInQueue(uint256 noteId) external view returns (bool) {
        return _pendingIdsQueue[noteId];
    }

    //#endregion
}
