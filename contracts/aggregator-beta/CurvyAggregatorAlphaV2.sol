// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { IPortalFactory } from "../portal/IPortalFactory.sol";
import { CurvyTypes } from "../utils/TypesV2.sol";
import { ICurvyAggregatorAlpha } from "./ICurvyAggregatorAlpha.sol";
import { ICurvyVault } from "../vault/ICurvyVault.sol";
import { PoseidonT4 } from "../aggregator-alpha/utils/PoseidonT4.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    ICurvyPendingNotesCommitmentVerifier_5,
    ICurvyAggregationVerifier_2_3,
    ICurvyWithdrawalVerifier_2
} from "./verifiers/ICurvyVerifiers.sol";

/**
 * @title CurvyAggregatorAlphaV2
 * @author Curvy Protocol (https://curvy.box)
 * @dev V2 aggregator wired to the v2 (NoHashing) zk-circuits:
 *      - verifyPendingNotesCommitment(batchSize, 30)         → 1 pubSignal
 *      - verifySingleAggregationNoHashing(maxInputs, 3, 30)  → 30/33 pubSignals
 *      - verifySingleWithdrawalNoHashing(maxInputs, 30)      → 6/9 pubSignals
 */
contract CurvyAggregatorAlphaV2 is
    ICurvyAggregatorAlpha,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20 for IERC20;

    address constant NATIVE_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant AUTHORITY_ROLE = keccak256("AUTHORITY_ROLE");

    uint256 internal constant AGG_MAX_OUTPUTS = 3;
    uint256 internal constant TREE_DEPTH = 30;
    uint256 internal constant ENC_NOTE_SIGNALS = 5;

    /// @dev BN254 scalar field. Verifier rejects public signals >= this value.
    ///      Circuit's `Bits2Num(256)` reconstructs sha256 bits as a field element,
    ///      so the on-chain inputHash must be reduced mod this prime.
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    //#region State (UUPS append-only)

    mapping(uint256 noteId => NoteStatus) public noteStatus;
    mapping(uint256 root => bool) public validNotesRoot;
    mapping(uint256 nullifier => bool) public aggregationNullifiers;
    mapping(uint256 nullifier => bool) public withdrawalNullifiers;

    uint256 public currentNotesTreeRoot;
    uint256 public currentNotesBatchIndex;
    uint256 public currentNullifiersBatchIndex;

    /// @dev Rate-based protocol fee (parts per thousand), enforced inside aggregation circuit
    ///      and on-contract for withdrawals.
    uint256 public protocolFeePerThousand;
    uint256 public gasFee;

    ICurvyVault public curvyVault;
    IPortalFactory public portalFactory;

    uint256 public currentNoteIndex;

    /// @dev Pending notes commitment verifier per (batchSize, treeDepth). 1 public signal.
    mapping(bytes32 configKey => address) public pendingNotesCommitmentVerifiersByConfig;

    /// @dev Aggregation verifier per (maxInputs, maxOutputs, treeDepth). Variable pubSignals.
    mapping(bytes32 configKey => address) public aggregationVerifiersByConfig;

    /// @dev Withdrawal verifier per (maxInputs, treeDepth). Variable pubSignals.
    mapping(bytes32 configKey => address) public withdrawalVerifiersByConfig;

    /// @dev BabyJub public key (x, y) of the protocol fee-note recipient.
    uint256[2] public feeNotePublicKey;

    //#endregion

    //#region Init

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __AccessControl_init();
        _setRoleAdmin(OPERATOR_ROLE, AUTHORITY_ROLE);
        _setRoleAdmin(AUTHORITY_ROLE, AUTHORITY_ROLE);
        _grantRole(AUTHORITY_ROLE, initialOwner);
        _grantRole(OPERATOR_ROLE, initialOwner);

        currentNotesTreeRoot = 4114686047564160449611603615418567457008101555090703535405891656262658644463;
    }

    function _authorizeUpgrade(address) internal override onlyRole(AUTHORITY_ROLE) {}

    //#endregion

    //#region Admin

    function updateConfig(
        CurvyTypes.AggregatorConfigurationUpdate memory _update
    ) external onlyRole(AUTHORITY_ROLE) returns (bool) {
        if (_update.curvyVault.code.length > 0) curvyVault = ICurvyVault(_update.curvyVault);
        if (_update.portalFactory.code.length > 0) portalFactory = IPortalFactory(_update.portalFactory);
        return true;
    }

    function setFees(uint256 _protocolFeePerThousand, uint256 _gasFee) external onlyRole(AUTHORITY_ROLE) {
        protocolFeePerThousand = _protocolFeePerThousand;
        gasFee = _gasFee;
    }

    function setFeeNotePublicKey(uint256 x, uint256 y) external onlyRole(AUTHORITY_ROLE) {
        feeNotePublicKey[0] = x;
        feeNotePublicKey[1] = y;
    }

    function setPendingNotesCommitmentVerifier(
        uint256 batchSize,
        uint256 treeDepth,
        address verifier
    ) external onlyRole(AUTHORITY_ROLE) {
        pendingNotesCommitmentVerifiersByConfig[_pendingNotesCommitmentVerifierKey(batchSize, treeDepth)] = verifier;
    }

    function setAggregationVerifier(
        uint256 maxInputs,
        uint256 maxOutputs,
        uint256 treeDepth,
        address verifier
    ) external onlyRole(AUTHORITY_ROLE) {
        aggregationVerifiersByConfig[_aggregationVerifierKey(maxInputs, maxOutputs, treeDepth)] = verifier;
    }

    function setWithdrawalVerifier(
        uint256 maxInputs,
        uint256 treeDepth,
        address verifier
    ) external onlyRole(AUTHORITY_ROLE) {
        withdrawalVerifiersByConfig[_withdrawalVerifierKey(maxInputs, treeDepth)] = verifier;
    }

    function _pendingNotesCommitmentVerifierKey(uint256 batchSize, uint256 treeDepth) private pure returns (bytes32) {
        return keccak256(abi.encode("pendingNotesCommitment", batchSize, treeDepth));
    }

    function _aggregationVerifierKey(
        uint256 maxInputs,
        uint256 maxOutputs,
        uint256 treeDepth
    ) private pure returns (bytes32) {
        return keccak256(abi.encode("aggregation", maxInputs, maxOutputs, treeDepth));
    }

    function _withdrawalVerifierKey(uint256 maxInputs, uint256 treeDepth) private pure returns (bytes32) {
        return keccak256(abi.encode("withdrawal", maxInputs, treeDepth));
    }

    //#endregion

    //#region Public — deposit

    /// @inheritdoc ICurvyAggregatorAlpha
    function autoShield(CurvyTypes.Note memory note) external payable override {
        if (!portalFactory.portalIsRegistered(msg.sender)) revert PortalNotRegistered();

        address tokenAddress = curvyVault.getTokenAddress(note.token);

        if (tokenAddress != NATIVE_ETH) {
            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), note.amount);
            IERC20(tokenAddress).forceApprove(address(curvyVault), note.amount);
        }

        curvyVault.deposit{ value: msg.value }(tokenAddress, address(this), note.amount);

        uint256 feeAmount = (note.amount * curvyVault.depositFee()) / 10000;
        uint256 netAmount = note.amount - feeAmount;
        uint256 noteId = PoseidonT4.hash([note.ownerHash, netAmount, note.token]);

        if (noteStatus[noteId] != NoteStatus.UNKNOWN) revert NoteAlreadyKnown();
        noteStatus[noteId] = NoteStatus.PENDING;

        uint256[] memory _noteIds = new uint256[](1);
        uint256[][2] memory _ephemeralKeys;
        _ephemeralKeys[0] = new uint256[](1);
        _ephemeralKeys[1] = new uint256[](1);
        uint16[] memory _viewTags = new uint16[](1);
        uint256[] memory _tokens = new uint256[](1);
        uint256[] memory _amounts = new uint256[](1);
        bool[] memory _isPlaintext = new bool[](1);

        _noteIds[0] = noteId;
        _ephemeralKeys[0][0] = note.ephemeralKey[0];
        _ephemeralKeys[1][0] = note.ephemeralKey[1];
        _viewTags[0] = note.viewTag;
        _tokens[0] = note.token;
        _amounts[0] = netAmount;
        _isPlaintext[0] = true;

        emit PendingNotes(_noteIds, _ephemeralKeys, _viewTags, _tokens, _amounts, _isPlaintext);
    }

    //#endregion

    //#region Public — commit pending notes

    /// @inheritdoc ICurvyAggregatorAlpha
    function commitPendingNotes(
        uint256 batchSize,
        uint256 treeDepth,
        uint256[] memory noteIds,
        uint256 newNotesRoot,
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c
    ) external override {
        if (noteIds.length != batchSize) revert NoteIdsLengthMismatch();

        address verifier = pendingNotesCommitmentVerifiersByConfig[
            _pendingNotesCommitmentVerifierKey(batchSize, treeDepth)
        ];
        if (verifier == address(0)) revert PendingNotesCommitmentVerifierNotConfigured();

        uint256 currentRoot = currentNotesTreeRoot;
        uint256 currentIndex = currentNoteIndex;
        uint256 newIndex = currentIndex;

        for (uint256 i = 0; i < batchSize; i += 1) {
            uint256 noteId = noteIds[i];
            if (noteId == 0) continue;
            if (noteStatus[noteId] != NoteStatus.PENDING) revert NoteNotScheduledForDeposit();
            noteStatus[noteId] = NoteStatus.INCLUDED;
            newIndex += 1;
        }

        // Mirror circomlib MultiInputSha256: sha256 of big-endian uint256s
        // [noteIds..., currentRoot, newRoot, currentIndex, newIndex]. The circuit
        // exposes this as a BN254 field element (Bits2Num(256) wraps mod r).
        uint256 rawInputHash = uint256(
            sha256(abi.encodePacked(noteIds, currentRoot, newNotesRoot, currentIndex, newIndex))
        );
        uint256 inputHash = rawInputHash % SNARK_SCALAR_FIELD;

        uint256[1] memory pub;
        pub[0] = inputHash;
        if (!ICurvyPendingNotesCommitmentVerifier_5(verifier).verifyProof(proof_a, proof_b, proof_c, pub))
            revert InvalidProof();

        currentNotesTreeRoot = newNotesRoot;
        currentNoteIndex = newIndex;
        validNotesRoot[newNotesRoot] = true;

        uint256 batchIndex = currentNotesBatchIndex;
        emit CommittedNotes(batchIndex, noteIds);
        currentNotesBatchIndex = batchIndex + 1;
    }

    //#endregion

    //#region Public — aggregation

    /// @inheritdoc ICurvyAggregatorAlpha
    function submitAggregationRequest(
        uint256 maxInputs,
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[] memory publicSignals
    ) external override {
        uint256 expectedLen = maxInputs + AGG_MAX_OUTPUTS + (AGG_MAX_OUTPUTS + 1) * ENC_NOTE_SIGNALS + 5;
        if (publicSignals.length != expectedLen) revert PublicSignalsLengthMismatch();

        address verifier = aggregationVerifiersByConfig[
            _aggregationVerifierKey(maxInputs, AGG_MAX_OUTPUTS, TREE_DEPTH)
        ];
        if (verifier == address(0)) revert AggregationVerifierNotConfigured();

        uint256 trailerStart = maxInputs + AGG_MAX_OUTPUTS + (AGG_MAX_OUTPUTS + 1) * ENC_NOTE_SIGNALS;

        if (!validNotesRoot[publicSignals[trailerStart]]) revert UnknownReferencedRoot();
        if (publicSignals[trailerStart + 1] != protocolFeePerThousand) revert FeeMismatch();
        if (publicSignals[trailerStart + 2] != gasFee) revert FeeMismatch();
        if (publicSignals[trailerStart + 3] != feeNotePublicKey[0]) revert FeeNotePublicKeyMismatch();
        if (publicSignals[trailerStart + 4] != feeNotePublicKey[1]) revert FeeNotePublicKeyMismatch();

        _verifyAggregation(maxInputs, verifier, proof_a, proof_b, proof_c, publicSignals);

        uint256[] memory nullifiers = new uint256[](maxInputs);
        for (uint256 i = 0; i < maxInputs; i += 1) {
            uint256 nf = publicSignals[i];
            if (nf == 0) continue;
            if (aggregationNullifiers[nf] || withdrawalNullifiers[nf]) revert NullifierAlreadyRegistered();
            aggregationNullifiers[nf] = true;
            nullifiers[i] = nf;
        }

        _processAndEmitAggregationOutputs(maxInputs, publicSignals);

        uint256 nullifierBatchIndex = currentNullifiersBatchIndex;
        emit CommittedNullifiers(nullifierBatchIndex, nullifiers);
        currentNullifiersBatchIndex = nullifierBatchIndex + 1;
    }

    function _processAndEmitAggregationOutputs(uint256 maxInputs, uint256[] memory publicSignals) private {
        uint256 totalNotes = AGG_MAX_OUTPUTS + 1;
        uint256[] memory noteIds = new uint256[](totalNotes);
        uint16[] memory viewTags = new uint16[](totalNotes);
        uint256[] memory tokens = new uint256[](totalNotes);
        uint256[] memory amounts = new uint256[](totalNotes);
        bool[] memory isPlaintext = new bool[](totalNotes);
        uint256[][2] memory ephemeralKeys;
        ephemeralKeys[0] = new uint256[](totalNotes);
        ephemeralKeys[1] = new uint256[](totalNotes);

        uint256 encBaseStart = maxInputs + AGG_MAX_OUTPUTS;
        for (uint256 i = 0; i < totalNotes; i += 1) {
            uint256 encBase = encBaseStart + i * ENC_NOTE_SIGNALS;
            uint256 noteId = i < AGG_MAX_OUTPUTS ? publicSignals[maxInputs + i] : 0;
            if (noteId != 0) {
                if (noteStatus[noteId] != NoteStatus.UNKNOWN) revert NoteAlreadyKnown();
                noteStatus[noteId] = NoteStatus.PENDING;
            }
            noteIds[i] = noteId;
            amounts[i] = publicSignals[encBase];
            tokens[i] = publicSignals[encBase + 1];
            ephemeralKeys[0][i] = publicSignals[encBase + 2];
            ephemeralKeys[1][i] = publicSignals[encBase + 3];
            viewTags[i] = uint16(publicSignals[encBase + 4]);
        }

        emit PendingNotes(noteIds, ephemeralKeys, viewTags, tokens, amounts, isPlaintext);
    }

    function _verifyAggregation(
        uint256 maxInputs,
        address verifier,
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[] memory publicSignals
    ) private view {
        if (maxInputs == 2) {
            uint256[30] memory pub;
            for (uint256 i = 0; i < 30; i += 1) pub[i] = publicSignals[i];
            if (!ICurvyAggregationVerifier_2_3(verifier).verifyProof(proof_a, proof_b, proof_c, pub))
                revert InvalidProof();
        } else {
            revert UnsupportedAggregationConfig();
        }
    }

    //#endregion

    //#region Public — withdrawal

    /// @inheritdoc ICurvyAggregatorAlpha
    function submitWithdrawalRequest(
        uint256 maxInputs,
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[] memory publicSignals
    ) external override {
        uint256 expectedLen = 1 + maxInputs + 3;
        if (publicSignals.length != expectedLen) revert PublicSignalsLengthMismatch();

        address verifier = withdrawalVerifiersByConfig[_withdrawalVerifierKey(maxInputs, TREE_DEPTH)];
        if (verifier == address(0)) revert WithdrawalVerifierNotConfigured();

        uint256 withdrawnAmount = publicSignals[0];
        uint256 notesRoot = publicSignals[1 + maxInputs];
        uint256 destinationAddress = publicSignals[1 + maxInputs + 1];
        uint256 tokenId = publicSignals[1 + maxInputs + 2];

        if (!validNotesRoot[notesRoot]) revert UnknownReferencedRoot();

        uint256 usedGasFee = gasFee;
        uint256 protocolFeeAmount = (withdrawnAmount * protocolFeePerThousand) / 1000;
        if (withdrawnAmount <= usedGasFee + protocolFeeAmount) revert NetAmountNonPositive();

        _verifyWithdrawal(maxInputs, verifier, proof_a, proof_b, proof_c, publicSignals);

        uint256[] memory nullifiers = new uint256[](maxInputs);
        for (uint256 i = 0; i < maxInputs; i += 1) {
            uint256 nf = publicSignals[1 + i];
            if (nf == 0) continue;
            if (withdrawalNullifiers[nf] || aggregationNullifiers[nf]) revert NullifierAlreadyRegistered();
            withdrawalNullifiers[nf] = true;
            nullifiers[i] = nf;
        }

        uint256 netAmount = withdrawnAmount - usedGasFee - protocolFeeAmount;
        if (usedGasFee > 0) {
            curvyVault.withdraw(tokenId, msg.sender, usedGasFee);
        }
        curvyVault.withdraw(tokenId, address(uint160(destinationAddress)), netAmount);

        uint256 nullifierBatchIndex = currentNullifiersBatchIndex;
        emit CommittedNullifiers(nullifierBatchIndex, nullifiers);
        currentNullifiersBatchIndex = nullifierBatchIndex + 1;
    }

    function _verifyWithdrawal(
        uint256 maxInputs,
        address verifier,
        uint256[2] memory proof_a,
        uint256[2][2] memory proof_b,
        uint256[2] memory proof_c,
        uint256[] memory publicSignals
    ) private view {
        if (maxInputs == 2) {
            uint256[6] memory pub;
            for (uint256 i = 0; i < 6; i += 1) pub[i] = publicSignals[i];
            if (!ICurvyWithdrawalVerifier_2(verifier).verifyProof(proof_a, proof_b, proof_c, pub))
                revert InvalidWithdrawProof();
        } else {
            revert UnsupportedWithdrawalConfig();
        }
    }

    //#endregion

    //#region View

    function getCurrentNotesTreeRoot() external view override returns (uint256) {
        return currentNotesTreeRoot;
    }

    function getCurrentNotesBatchIndex() external view override returns (uint256) {
        return currentNotesBatchIndex;
    }

    function getCurrentNullifiersBatchIndex() external view override returns (uint256) {
        return currentNullifiersBatchIndex;
    }

    function getCurrentNoteIndex() external view override returns (uint256) {
        return currentNoteIndex;
    }

    function getPendingNotesCommitmentVerifier(uint256 batchSize, uint256 treeDepth) external view returns (address) {
        return pendingNotesCommitmentVerifiersByConfig[_pendingNotesCommitmentVerifierKey(batchSize, treeDepth)];
    }

    function getAggregationVerifier(
        uint256 maxInputs,
        uint256 maxOutputs,
        uint256 treeDepth
    ) external view override returns (address) {
        return aggregationVerifiersByConfig[_aggregationVerifierKey(maxInputs, maxOutputs, treeDepth)];
    }

    function getWithdrawalVerifier(uint256 maxInputs, uint256 treeDepth) external view override returns (address) {
        return withdrawalVerifiersByConfig[_withdrawalVerifierKey(maxInputs, treeDepth)];
    }

    //#endregion
}
