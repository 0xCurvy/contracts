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
import {ICurvyAggregatorAlphaV2} from "./ICurvyAggregatorAlphaV2.sol";
import {ICurvyVaultV3} from "../vault/ICurvyVaultV3.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// audit(operator/authority): role-based access control via OZ AccessControl
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PoseidonT4} from "./utils/PoseidonT4.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title CurvyAggregator
 * @author Curvy Protocol (https://curvy.box)
 * @dev Curvy's Aggregator contract.
 */
contract CurvyAggregatorAlphaV6 is
    ICurvyAggregatorAlphaV2,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20 for IERC20;
    //#region Events

    event DepositedNote(uint256 noteId);

    //#endregion

    address constant NATIVE_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // audit(operator/authority): operational role; rotated by AUTHORITY_ROLE
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    // audit(operator/authority): security-critical role (upgrades, updateConfig)
    bytes32 public constant AUTHORITY_ROLE = keccak256("AUTHORITY_ROLE");

    //#region State variables

    // Maximum number of notes to commit in deposit
    uint256 public maxDeposits;
    // Maximum number of aggregations in one aggregation batch proof
    uint256 public maxAggregations;
    // Maximum number of withdrawals in one withdrawal batch proof
    uint256 public maxWithdrawals;

    // Queue of commited note ids waiting for proof verification and deposit batch commitment
    mapping(uint256 => bool) private _pendingIdsQueue;

    // Root of the tree containing all notes.
    uint256 private _notesTreeRoot;
    // Root of the tree contaiing all of the used nullifiers.
    uint256 private _nullifiersTreeRoot;

    // Curvy's vault contract
    ICurvyVaultV3 public curvyVault;

    //Curvy's insertion verifier.
    ICurvyInsertionVerifier public insertionVerifier;
    //Curvy's aggregation verifier.
    ICurvyAggregationVerifier public aggregationVerifier;
    //Curvy's withdraw verifier.
    ICurvyWithdrawVerifierV3 public withdrawVerifier;

    // Curvy's portal factory contract;
    IPortalFactory public portalFactory;

    //#endregion

    //#region Init functions

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);

        // audit(operator/authority): seed roles on first deploy
        __AccessControl_init();
        _setRoleAdmin(OPERATOR_ROLE, AUTHORITY_ROLE);
        _setRoleAdmin(AUTHORITY_ROLE, AUTHORITY_ROLE);
        _grantRole(AUTHORITY_ROLE, initialOwner);
        _grantRole(OPERATOR_ROLE, initialOwner);
    }

    // audit(operator/authority): bootstraps AccessControl on existing V6 proxies (initialize already ran).
    // Pre-AC `_authorizeUpgrade` (onlyOwner) gates the upgrade itself; this reinitializer runs atomically
    // with the upgrade and seeds OPERATOR_ROLE + AUTHORITY_ROLE on the current owner.
    function bootstrapAccessControl() external reinitializer(2) onlyOwner {
        __AccessControl_init();
        _setRoleAdmin(OPERATOR_ROLE, AUTHORITY_ROLE);
        _setRoleAdmin(AUTHORITY_ROLE, AUTHORITY_ROLE);
        _grantRole(AUTHORITY_ROLE, owner());
        _grantRole(OPERATOR_ROLE, owner());
    }

    // audit(operator/authority): upgrades gated by AUTHORITY_ROLE
    function _authorizeUpgrade(address) internal override onlyRole(AUTHORITY_ROLE) {}

    //#endregion

    //#region Owner functions

    // audit(operator/authority): authority-gated
    function updateConfig(CurvyTypes.AggregatorConfigurationUpdateV2 memory _update) external onlyRole(AUTHORITY_ROLE) returns (bool) {
        // audit(2026-Q1): Missing Smart Contract address check - require code at address (also rejects EOAs and address(0))
        if (_update.insertionVerifier.code.length > 0) {
            insertionVerifier = ICurvyInsertionVerifier(_update.insertionVerifier);
        }
        // audit(2026-Q1): Missing Smart Contract address check
        if (_update.aggregationVerifier.code.length > 0) {
            aggregationVerifier = ICurvyAggregationVerifier(_update.aggregationVerifier);
        }
        // audit(2026-Q1): Missing Smart Contract address check
        if (_update.withdrawVerifier.code.length > 0) {
            withdrawVerifier = ICurvyWithdrawVerifierV3(_update.withdrawVerifier);
        }
        // audit(2026-Q1): Missing Smart Contract address check
        if (_update.curvyVault.code.length > 0) {
            curvyVault = ICurvyVaultV3(_update.curvyVault);
        }
        // audit(2026-Q1): Missing Smart Contract address check
        if (_update.portalFactory.code.length > 0) {
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

    //#endregions

    //#region Public functions

    function autoShield(CurvyTypes.Note memory note) external payable {
        // Only allow auto shielding of portals that were deployed through the portalFactory
        if (!portalFactory.portalIsRegistered(msg.sender)) revert PortalNotRegistered();

        // This will revert if tokenId is not found.
        address tokenAddress = curvyVault.getTokenAddress(note.token);

        if (tokenAddress != NATIVE_ETH) {
            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), note.amount);
            IERC20(tokenAddress).forceApprove(address(curvyVault), note.amount);
        }

        curvyVault.deposit{value: msg.value}(tokenAddress, address(this), note.amount);

        uint256 feeAmount = note.amount * curvyVault.depositFee() / 10000;

        uint256 noteId = PoseidonT4.hash([note.ownerHash,  note.amount - feeAmount, note.token]);

        _pendingIdsQueue[noteId] = true;

        emit DepositedNote(noteId);
    }

    function commitDepositBatch(
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[4] memory publicInputs
    ) public {
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
    }

    function commitAggregationBatch(
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[14] memory publicInputs
    ) public {
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
    }

    function commitWithdrawalBatch(
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[9] memory publicInputs
    ) public {
        if (publicInputs[2] != _nullifiersTreeRoot) {
            revert CurrentNullifierTreeRootMismatch();
        }
        if (publicInputs[1] != _notesTreeRoot) revert CurrentNoteTreeRootMismatch();

        if (!withdrawVerifier.verifyProof(proof_a, proof_b, proof_c, publicInputs)) revert InvalidProof();

        // Update the root of the nullifier tree
        _nullifiersTreeRoot = publicInputs[0];

        uint256 numPublicInputs = publicInputs.length;

        // Transfer withdrawals
        for (uint256 i = 0; i < maxWithdrawals; i += 1) {
            uint256 amount = publicInputs[3 + i];
            address destinationAddress = address(uint160(publicInputs[3 + maxWithdrawals + i]));
            if (amount != 0) {
                curvyVault.withdraw(
                    publicInputs[numPublicInputs - 1], // tokenId
                    destinationAddress,
                    amount
                );
            }
        }
    }

    //#endregion

    //#region View functions

    function getNoteTreeRoot() external view returns (uint256) {
        return _notesTreeRoot;
    }

    function getNullifiersTreeRoot() external view returns (uint256) {
        return _nullifiersTreeRoot;
    }

    function noteInQueue(uint256 noteId) external view returns (bool) {
        return _pendingIdsQueue[noteId];
    }

    //#endregion
}
