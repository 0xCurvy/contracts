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

contract CurvyAggregator_wrap_FuzzTest is BoilerPlate {
    function testFuzz_singleWrapNative(uint256 _fromId, uint256 _amountPercentage) public {
        uint256 _maxEstimatedCost = 0.00001 ether;
        vm.assume(_fromId < N_USER);

        address _from = users[_fromId];
        address _token = CurvyAggregator_Constants.NATIVE_TOKEN;

        _amountPercentage = 1 + _amountPercentage % 99;
        uint256 _amount = ((address(_from).balance - _maxEstimatedCost) * _amountPercentage) / 100;

        CurvyAggregator_Types.Note[] memory _notes = new CurvyAggregator_Types.Note[](1);
        _notes[0] =
            CurvyAggregator_Types.Note({token: uint256(uint160(address(_token))), amount: _amount, ownerHash: 0});

        wrapNative(MOCKED_CSUC, _notes);
    }

    function testFuzz_multipleWrapNative(uint256 _fromId, uint256 _wrapCount) public {
        uint256 _maxEstimatedCost = 0.00001 ether;
        vm.assume(_fromId < N_USER);

        address _from = users[_fromId];
        address _token = CurvyAggregator_Constants.NATIVE_TOKEN;

        _wrapCount = 1 + _wrapCount % 10;
        CurvyAggregator_Types.Note[] memory _notes = new CurvyAggregator_Types.Note[](_wrapCount);

        uint256 _maxAmount = address(_from).balance - _maxEstimatedCost;
        uint256 _runningTotalAmount = 0;
        for (uint256 i = 0; i < _wrapCount; ++i) {
            uint256 _amountPercentage = 1 + (i * 10) % 99; // Vary the amount percentage for each wrap
            uint256 _amount = ((_maxAmount - _runningTotalAmount) * _amountPercentage) / 100;
            _runningTotalAmount += _amount;
            _notes[i] =
                CurvyAggregator_Types.Note({token: uint256(uint160(address(_token))), amount: _amount, ownerHash: 0});
        }

        wrapNative(MOCKED_CSUC, _notes);
    }

    function testFuzz_multipleUserWrapNative(uint256 _fromCount, uint256 _wrapCount) public {
        _fromCount = 1 + _fromCount % N_USER;
        _wrapCount = 1 + _wrapCount % 10;
        for (uint256 i = 0; i < _fromCount; ++i) {
            testFuzz_multipleWrapNative(i, _wrapCount);
        }
    }

    function testFuzz_singleWrapERC20(uint256 _fromId, uint256 _amountPercentage) public {
        vm.assume(_fromId < N_USER);

        address _from = users[_fromId];
        address _token = address(m20Tokens[(_fromId + 1) % N_ERC20_TOKENS]);

        _amountPercentage = 1 + _amountPercentage % 99;
        uint256 _amount = ((getBalance(_token, _from)) * _amountPercentage) / 100;

        CurvyAggregator_Types.Note[] memory _notes = new CurvyAggregator_Types.Note[](1);
        _notes[0] =
            CurvyAggregator_Types.Note({token: uint256(uint160(address(_token))), amount: _amount, ownerHash: 0});

        approveAndWrapERC20(MOCKED_CSUC, _notes);
    }

    function testFuzz_multipleWrapERC20(uint256 _fromId, uint256 _wrapCount) public {
        vm.assume(_fromId < N_USER);

        address _from = users[_fromId];
        address _token = address(m20Tokens[(_fromId + 1) % N_ERC20_TOKENS]);

        _wrapCount = 1 + _wrapCount % 10;
        CurvyAggregator_Types.Note[] memory _notes = new CurvyAggregator_Types.Note[](_wrapCount);

        uint256 _maxAmount = getBalance(_token, _from);
        uint256 _runningTotalAmount = 0;
        for (uint256 i = 0; i < _wrapCount; ++i) {
            uint256 _amountPercentage = 1 + (i * 10) % 99; // Vary the amount percentage for each wrap
            uint256 _amount = ((_maxAmount - _runningTotalAmount) * _amountPercentage) / 100;
            _runningTotalAmount += _amount;
            _notes[i] =
                CurvyAggregator_Types.Note({token: uint256(uint160(address(_token))), amount: _amount, ownerHash: 0});
        }

        approveAndWrapERC20(MOCKED_CSUC, _notes);
    }
}
