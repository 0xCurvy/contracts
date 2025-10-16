// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

/**
 * @title CurvyAggregator_Types
 * @author Curvy Protocol (https://curvy.box)
 * @dev Types used by the Curvy's Aggregator contract.
 */
library CurvyAggregator_Types {
    /**
     * @notice Configuration update structure used by the Aggregator.
     * @dev This structure is used to update the verifiers for insertion, aggregation, and withdrawal.
     * @param insertionVerifier Address of the new insertion verifier.
     * @param aggregationVerifier Address of the new aggregation verifier.
     * @param withdrawVerifier Address of the new withdrawal verifier.
     * @param operator Address of the Curvy Operator that will be used for the Aggregator.
     * @param feeCollector Address of the Curvy Fee Collector that will be used for the Aggregator.
     */
    struct ConfigurationUpdate {
        address insertionVerifier;
        address aggregationVerifier;
        address withdrawVerifier;
        address operator;
        address feeCollector;
        address tokenWrapper;
    }

    /**
     * @notice Note representation with `deadline` used by the Aggregator.
     * @dev The member `deadline` is the `block.number` after which the note is considered
     *      to be 'rejected' by the Curvy `operator`, and the User can issue a withdraw.
     * @param note Note info.
     * @param sender Address of the User that created the note.
     * @param deadline Equal to the `block.number`after which the note is considered to be 'rejected'.
     * @param included Flag that states whether the wrap request was processed.
     * @param cancelled Flag that states if the note was 'cancelled' - withdrawn, after being 'rejected'.
     */
    struct NoteWithMetaData {
        Note note;
        address sender;
        uint256 deadline;
        bool included;
        bool cancelled;
    }

    /**
     * @notice Note representation used by the Aggregator.
     * @param ownerHash The PoseidonHash(ownerAx, ownerAy, sharedSecret)
     * @param token Token included in the note.
     * @param amount Amount of tokens that the note holds.
     */
    struct Note {
        uint256 ownerHash;
        uint256 token;
        uint256 amount;
    }

    /**
     * @notice Structure used for processing pending wrap requests.
     * @param a The first part of the Groth16 proof.
     * @param b The second part of the Groth16 proof.
     * @param c The third part of the Groth16 proof.
     * @param inputs Public signals of the circuit being used.
     */
    struct WrappingZKP {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[152] inputs;
    }

    /**
     * @notice Structure used for processing pending wrap requests.
     * @param a The first part of the Groth16 proof.
     * @param b The second part of the Groth16 proof.
     * @param c The third part of the Groth16 proof.
     * @param inputs Public signals of the circuit being used.
     */
    struct ActionExecutionZKP {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[46] inputs;
    }

    /**
     * @notice Structure used for processing pending wrap requests.
     * @param a The first part of the Groth16 proof.
     * @param b The second part of the Groth16 proof.
     * @param c The third part of the Groth16 proof.
     * @param inputs Public signals of the circuit being used.
     */
    struct UnwrappingZKP {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[26] inputs;
    }
}