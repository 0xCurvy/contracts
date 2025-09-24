// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

/**
 * @title CurvyAggregator_Constants
 * @author Curvy Protocol (https://curvy.box)
 * @dev Constants used by the Curvy's Aggregator contract.
 */
library CurvyAggregator_Constants {
    /// The maximum number of blocks before a note is considered 'rejected'
    uint256 public constant NOTE_INCLUSION_BLOCK_OFFSET = 1_000;

    /// Constant used to represent the 'native' token in the Aggregator.
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// The CSUC Action Handler ID
    uint256 public constant CURVY_AGGREGATOR_CSUC_ACTION_HANDLER_ID =
    uint256(keccak256(abi.encode("AGGREGATOR_ACTION_HANDLER")));

    /// The number of fields in any Note
    uint256 public constant CURVY_INSERTION_NOTE_FIELDS = 3;

    /// The maximum base points = 100%
    uint256 public constant TOTAL_BASE_POINTS = 10_000;

    // Response values for ERC115500000
    bytes4 internal constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

    // Snark scalar field
    uint256 public constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
}
