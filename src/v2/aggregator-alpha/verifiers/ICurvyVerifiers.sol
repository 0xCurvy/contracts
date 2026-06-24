// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

interface ICurvyVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input
    ) external view returns (bool r);
}

/**
 * @notice Interface for the Curvy Pending Notes Commitment Verifier.
 */
interface ICurvyPendingNotesCommitmentVerifier_5 is ICurvyVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) external view returns (bool r);
}

/**
 * @notice Interface for the Curvy Aggregation Verifier.
 */
interface ICurvyAggregationVerifier_2_3 is ICurvyVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[31] memory input
    ) external view returns (bool r);
}

/**
 * @notice Interface for the Curvy Withdraw Verifier.
 */
interface ICurvyWithdrawalVerifier_2 is ICurvyVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[6] memory input
    ) external view returns (bool r);
}
