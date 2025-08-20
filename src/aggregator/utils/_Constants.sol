// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {CSUC_Constants} from "../../csuc/utils/_Constants.sol";

/**
 * @title CurvyAggregator_Constants
 * @author Curvy Protocol (https://curvy.box)
 * @dev Constants used by the Curvy's Aggregator contract.
 */
library CurvyAggregator_Constants {
    /// The maximum number of blocks before a note is considered 'rejected'
    uint256 public constant NOTE_INCLUSION_BLOCK_OFFSET = 1_000;

    /// Constant used to represent the 'native' token in the Aggregator.
    address public constant NATIVE_TOKEN = CSUC_Constants.NATIVE_TOKEN;

    /// The CSUC Action Handler ID
    uint256 public constant CURVY_AGGREGATOR_CSUC_ACTION_HANDLER_ID =
        uint256(keccak256(abi.encode("AGGREGATOR_ACTION_HANDLER")));

    /// The number of fields in any Note
    uint256 public constant CURVY_INSERTION_NOTE_FIELDS = 3;

    /// The maximum base points = 100%
    uint256 public constant TOTAL_BASE_POINTS = 10_000;
}
