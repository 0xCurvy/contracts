// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

/**
 * @title CurvyVerifiers interfaces
 * @author Curvy Protocol (https://curvy.box)
 * @dev Wrapper arround Curvy's Verifiers contracts where interfaces are manually created.
 */

/**
 * @notice Interface for the Curvy Insertion Verifier.
 */
interface ICurvyInsertionVerifier {
    /**
     * @notice Verifies a proof for inserting a note into the note tree.
     * @param a The first part of the proof.
     * @param b The second part of the proof.
     * @param c The third part of the proof.
     * @param input The public input to the proof.
     * @return r True if the proof is valid, false otherwise.
     */
    function verifyProof(uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c, uint256[152] memory input)
    external
    view
    returns (bool r);
}

/**
 * @notice Interface for the Curvy Withdraw Verifier.
 */
interface ICurvyWithdrawVerifier {
    /**
     * @notice Verifies a proof for withdrawing a note from the note tree.
     * @param a The first part of the proof.
     * @param b The second part of the proof.
     * @param c The third part of the proof.
     * @param input The public input to the proof.
     * @return r True if the proof is valid, false otherwise.
     */
    function verifyProof(uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c, uint256[26] memory input)
    external
    view
    returns (bool r);
}

/**
 * @notice Interface for the Curvy Aggregation Verifier.
 */
interface ICurvyAggregationVerifier {
    /**
     * @notice Verifies a proof for aggregating notes.
     * @param a The first part of the proof.
     * @param b The second part of the proof.
     * @param c The third part of the proof.
     * @param input The public input to the proof.
     * @return r True if the proof is valid, false otherwise.
     */
    function verifyProof(uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c, uint256[46] memory input)
    external
    view
    returns (bool r);
}