// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {CSUC_BoilerPlate, Strings} from "../../../_BoilerPlate.t.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {CSUC, CSUC_Types, CSUC_Constants} from "../../../../../src/csuc/CSUC.sol";

contract CSUC_operatorExecute_Transfer_UnitTest is CSUC_BoilerPlate {
    function setUp() public {
        CSUC_BoilerPlate.multipleSetUp();
    }

    function test_Native_SingleTransfer() public {
        uint256 _nTransfers = 1;

        CSUC_Types.Action memory _action =
            _createTransferAction(users[0], CSUC_Constants.NATIVE_TOKEN, users[0].balance / 4);

        uint256 _totalGasUsed = _operatorExecute();

        assertEq(csuc.nonceOf(_action.from, _action.payload.token), 1);

        string memory _snapId = string.concat("test_Native_SingleTransfer:#Actions=", Strings.toString(_nTransfers));
        _snapshotGas(_snapId, _totalGasUsed, 1);
        vm.snapshotValue(string.concat(_snapId, ":AverageGasCostPerAction"), _totalGasUsed / _nTransfers);
    }

    function test_Native_MultipleTransfer() public {
        uint256 _nTransfers = users.length;

        CSUC_Types.Action[] memory _actions = new CSUC_Types.Action[](_nTransfers);

        for (uint256 i = 0; i < _nTransfers; ++i) {
            _actions[i] = _createTransferAction(users[i], CSUC_Constants.NATIVE_TOKEN, users[i].balance / 4);
        }

        uint256 _totalGasUsed = _operatorExecute();

        for (uint256 i = 0; i < _nTransfers; ++i) {
            assertEq(csuc.nonceOf(_actions[i].from, _actions[i].payload.token), 1);
        }

        string memory _snapId = string.concat("test_Native_MultipleTransfer:#Actions=", Strings.toString(_nTransfers));
        _snapshotGas(_snapId, _totalGasUsed, 1);
        vm.snapshotValue(string.concat(_snapId, ":AverageGasCostPerAction"), _totalGasUsed / _nTransfers);
    }

    function test_ERC20_SingleTransfer() public {
        uint256 _nTransfers = 1;

        address _token = address(m20[0]);
        CSUC_Types.Action memory _action = _createTransferAction(users[0], _token, IERC20(_token).balanceOf(users[0]));

        uint256 _totalGasUsed = _operatorExecute();

        assertEq(csuc.nonceOf(_action.from, _action.payload.token), 1);

        string memory _snapId = string.concat("test_ERC20_SingleTransfer:#Actions=", Strings.toString(_nTransfers));
        _snapshotGas(_snapId, _totalGasUsed, 1);
        vm.snapshotValue(string.concat(_snapId, ":AverageGasCostPerAction"), _totalGasUsed / _nTransfers);
    }

    function test_ERC20_MultipleTransfer() public {
        uint256 _nTransfers = users.length;

        CSUC_Types.Action[] memory _actions = new CSUC_Types.Action[](_nTransfers);

        for (uint256 i = 0; i < _nTransfers; ++i) {
            address _token = address(m20[i % m20.length]);
            _actions[i] = _createTransferAction(users[i], _token, IERC20(_token).balanceOf(users[i]));
        }

        uint256 _totalGasUsed = _operatorExecute();

        for (uint256 i = 0; i < _nTransfers; ++i) {
            assertEq(csuc.nonceOf(_actions[i].from, _actions[i].payload.token), 1);
        }

        string memory _snapId = string.concat("test_ERC20_MultipleTransfer:#Actions=", Strings.toString(_nTransfers));
        _snapshotGas(_snapId, _totalGasUsed, 1);
        vm.snapshotValue(string.concat(_snapId, ":AverageGasCostPerAction"), _totalGasUsed / _nTransfers);
    }
}
