// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {BoilerPlate} from "../../_BoilerPlate.t.sol";

import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {
    ICurvyAggregator,
    CurvyAggregator,
    CurvyAggregator_Types,
    CurvyAggregator_Constants
} from "../../../../src/aggregator/CurvyAggregator.sol";

contract CurvyAggregator_operatorExecuteInvalidProofs_FuzzTest is BoilerPlate {
    function testFuzz_operatorExecuteInvalidProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[46] memory inputs
    ) public {
        // Note: there's a small chance that the proof verification and inputs will be valid
        vm.startBroadcast(operator);
        vm.expectRevert();
        curvyAggregator.operatorExecute(CurvyAggregator_Types.ActionExecutionZKP({a: a, b: b, c: c, inputs: inputs}));
    }
}