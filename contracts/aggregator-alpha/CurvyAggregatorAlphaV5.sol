// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import "../portal/IPortalFactory.sol";
import {
    ICurvyInsertionVerifier,
    ICurvyAggregationVerifier,
    ICurvyWithdrawVerifier,
    ICurvyWithdrawVerifierV3
} from "./verifiers/ICurvyVerifiersAlpha.sol";
import {CurvyTypes} from "../utils/Types.sol";
import {ICurvyAggregatorAlpha} from "./ICurvyAggregatorAlpha.sol";
import {ICurvyVault} from "../vault/ICurvyVault.sol";
import {ICurvyVaultV2} from "../vault/ICurvyVaultV2.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PoseidonT4} from "./utils/PoseidonT4.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title CurvyAggregator
 * @author Curvy Protocol (https://curvy.box)
 * @dev Curvy's Aggregator contract.
 */
contract CurvyAggregatorAlphaV5 is ICurvyAggregatorAlpha, Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    //#region Events

    event DepositedNote(uint256 noteId);

    //#endregion

    address constant NATIVE_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    //#region State variables

    // Maximum number of notes to commit in deposit
    uint256 public maxDeposits;
    // TODO: Maximum number of notes to commit in aggregation or aggregation requests in one aggregation batch proof?
    // Maximum number of aggregations
    uint256 public maxAggregations;
    // Maximum number of withdrawals
    uint256 public maxWithdrawals;

    // TODO: This is not waiting on deposit commitment, this *IS A COMMITMENT* waiting on proof verification in the future
    // Queue of note ids waiting for deposit commitment
    mapping(uint256 => bool) private _pendingIdsQueue;

    // Root of the tree containing all notes.
    uint256 private _notesTreeRoot;
    // Root of the tree contaiing all of the used nullifiers.
    uint256 private _nullifiersTreeRoot;

    // Curvy's vault contract
    ICurvyVault public curvyVault;

    //Curvy's insertion verifier.
    ICurvyInsertionVerifier public insertionVerifier;
    //Curvy's aggregation verifier.
    ICurvyAggregationVerifier public aggregationVerifier;
    //Curvy's withdraw verifier.
    ICurvyWithdrawVerifier public withdrawVerifier;

    // Curvy's portal factory contract;
    IPortalFactory public portalFactory;

    // TODO: This doesn't need to be a completely separate storage var, as the underlying data type is address, just the interface is changed.
    ICurvyVaultV2 public curvyVaultV2;

    ICurvyWithdrawVerifierV3 public withdrawVerifierV3;

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

    function updateConfig(CurvyTypes.AggregatorConfigurationUpdateV2 memory _update)
        external
        onlyOwner
        returns (bool)
    {
        if (_update.insertionVerifier != address(0)) {
            insertionVerifier = ICurvyInsertionVerifier(_update.insertionVerifier);
        }
        if (_update.aggregationVerifier != address(0)) {
            aggregationVerifier = ICurvyAggregationVerifier(_update.aggregationVerifier);
        }
        if (_update.withdrawVerifier != address(0)) {
            withdrawVerifierV3 = ICurvyWithdrawVerifierV3(_update.withdrawVerifier);
        }
        if (_update.curvyVault != address(0)) {
            curvyVaultV2 = ICurvyVaultV2(_update.curvyVault);
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

    // TODO: Add commment
    function reset(uint256 newNotesTreeRoot, uint256 newNullifiersTreeRoot) external onlyOwner {
        _notesTreeRoot = newNotesTreeRoot;
        _nullifiersTreeRoot = newNullifiersTreeRoot;
    }

    //#endregions

    //#region Public functions

    function autoShield(CurvyTypes.Note memory note, address tokenAddress) external payable {
        // Only allow auto shielding of portals that were deployed through the portalFactory
        if (!portalFactory.portalIsRegistered(msg.sender)) revert PortalNotRegistered();

        if (tokenAddress != address(0) && tokenAddress != NATIVE_ETH) {
            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), note.amount);
            IERC20(tokenAddress).forceApprove(address(curvyVaultV2), note.amount);
        }

        curvyVaultV2.deposit{value: msg.value}(tokenAddress, address(this), note.amount);

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
                if (!_pendingIdsQueue[noteId]) revert NoteNotScheduledForDeposit();
                delete _pendingIdsQueue[noteId];
            }
        }

        uint256 numPublicInputs = publicInputs.length;

        if (_notesTreeRoot != publicInputs[numPublicInputs - 2]) revert InvalidNotesRoot();

        if (!insertionVerifier.verifyProof(proof_a, proof_b, proof_c, publicInputs)) revert InvalidProof();

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

        if (_notesTreeRoot != oldNotesTreeRoot) revert CurrentNoteTreeRootMismatch();
        if (_nullifiersTreeRoot != oldNullifiersTreeRoot) revert CurrentNullifierTreeRootMismatch();

        if (!aggregationVerifier.verifyProof(proof_a, proof_b, proof_c, publicInputs)) revert InvalidProof();

        // Update the roots of the trees
        _notesTreeRoot = newNotesTreeRoot;
        _nullifiersTreeRoot = newNullifiersTreeRoot;

        return true;
    }

    // TODO: Why are we returning bool here? In which case do we return false? Same goes for other proofs being verified.
    function commitWithdrawalBatch(
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[9] memory publicInputs
    ) public returns (bool) {
        if (publicInputs[2] != _nullifiersTreeRoot) revert CurrentNullifierTreeRootMismatch();
        if (publicInputs[1] != _notesTreeRoot) revert CurrentNoteTreeRootMismatch();

        if (!withdrawVerifierV3.verifyProof(proof_a, proof_b, proof_c, publicInputs)) revert InvalidProof();

        // Update the root of the nullifier tree
        _nullifiersTreeRoot = publicInputs[0];

        uint256 numPublicInputs = publicInputs.length;

        // Transfer withdrawals
        for (uint256 i = 0; i < maxWithdrawals; i += 1) {
            uint256 amount = publicInputs[3 + i];
            address destinationAddress = address(uint160(publicInputs[3 + maxWithdrawals + i]));
            if (amount != 0) {
                curvyVaultV2.withdraw(
                    publicInputs[numPublicInputs - 1], // tokenId
                    destinationAddress,
                    amount
                );
            }
        }

        return true;
    }

    //#endregion

    //#region View functions

    function getNoteTreeRoot() external view returns (uint256) {
        return _notesTreeRoot;
    }

    // TODO: rename to nuillifierS
    function getNullifierTreeRoot() external view returns (uint256) {
        return _nullifiersTreeRoot;
    }

    function noteInQueue(uint256 noteId) external view returns (bool) {
        return _pendingIdsQueue[noteId];
    }

    //#endregion
}
