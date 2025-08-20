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

contract CurvyAggregator_wrap_UnitTest is BoilerPlate {
    function test_SingleWrapNative() public {
        address _from = users[0];
        address _token = CurvyAggregator_Constants.NATIVE_TOKEN;
        uint256 _amount = address(_from).balance / 2;

        CurvyAggregator_Types.Note[] memory _notes = new CurvyAggregator_Types.Note[](1);
        _notes[0] =
            CurvyAggregator_Types.Note({token: uint256(uint160(address(_token))), amount: _amount, ownerHash: 0});
        wrapNative(MOCKED_CSUC, _notes);
    }

    function test_SingleWrapERC20() public {
        address _from = users[0];
        address _token = address(m20Tokens[0]);
        uint256 _amount = IERC20(_token).balanceOf(_from) / 2;

        CurvyAggregator_Types.Note[] memory _notes = new CurvyAggregator_Types.Note[](1);
        _notes[0] =
            CurvyAggregator_Types.Note({token: uint256(uint160(address(_token))), amount: _amount, ownerHash: 0});
        approveAndWrapERC20(MOCKED_CSUC, _notes);
    }
}
