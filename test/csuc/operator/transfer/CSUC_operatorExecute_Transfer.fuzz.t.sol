// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {CSUC_BoilerPlate, Strings} from "../../_BoilerPlate.t.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {CSUC, CSUC_Types, CSUC_Constants} from "../../../../src/csuc/CSUC.sol";

contract CSUC_operatorExecute_Transfer_FuzzTest is CSUC_BoilerPlate {
    function setUp() public {
        CSUC_BoilerPlate.multipleSetUp();
    }

    function testFuzz_Native_SingleTransfer(uint256 _userId, uint256 _amountPercentage) public {
        _userId %= users.length;
        _amountPercentage = 1 + (_amountPercentage) % 100;

        _createTransferAction(
            users[_userId], CSUC_Constants.NATIVE_TOKEN, (_amountPercentage * users[_userId].balance) / 100
        );

        uint256 _totalGasUsed = _operatorExecute();
        uint256 _nTransfers = 1;

        string memory _snapId = string.concat("testFuzz_Native_SingleTransfer:#Actions=", Strings.toString(_nTransfers));
        _snapshotGas(_snapId, _totalGasUsed, 1);
        vm.snapshotValue(string.concat(_snapId, ":AverageGasCostPerAction"), _totalGasUsed / _nTransfers);
    }

    function testFuzz_Native_MultipleTransfer(uint256[] memory _amountPercentages) public {
        vm.assume(_amountPercentages.length > 0 && _amountPercentages.length <= users.length);
        uint256 _nTransfers = _amountPercentages.length;

        for (uint256 i = 0; i < _nTransfers; ++i) {
            uint256 _userId = i;
            uint256 _amountPercentage = _amountPercentages[i] % 100;
            uint256 _amount = 1 + (_amountPercentage * users[_userId].balance) / 100;
            _createTransferAction(users[_userId], CSUC_Constants.NATIVE_TOKEN, _amount);
        }

        _shuffleActions();

        uint256 _totalGasUsed = _operatorExecute();

        string memory _snapId =
            string.concat("testFuzz_Native_MultipleTransfer:#Actions=", Strings.toString(_nTransfers));
        _snapshotGas(_snapId, _totalGasUsed, 1);
        vm.snapshotValue(string.concat(_snapId, ":AverageGasCostPerAction"), _totalGasUsed / _nTransfers);
    }

    function testFuzz_ERC20_SingleTransfer(uint256 _userId, uint256 _tokenId, uint256 _amountPercentage) public {
        address _user = users[_userId % users.length];
        address _token = address(m20[_tokenId % m20.length]);
        uint256 _amount = ((1 + (_amountPercentage) % 100) * IERC20(_token).balanceOf(_user)) / 100;
        _createTransferAction(_user, _token, _amount);

        uint256 _totalGasUsed = _operatorExecute();
        uint256 _nTransfers = 1;

        string memory _snapId = string.concat("testFuzz_ERC20_SingleTransfer:#Actions=", Strings.toString(_nTransfers));
        _snapshotGas(_snapId, _totalGasUsed, 1);
        vm.snapshotValue(string.concat(_snapId, ":AverageGasCostPerAction"), _totalGasUsed / _nTransfers);
    }

    function testFuzz_ERC20_MultipleTransfer(uint256[] memory _amountPercentages) public {
        vm.assume(_amountPercentages.length > 0 && _amountPercentages.length <= users.length);
        uint256 _nTransfers = _amountPercentages.length;

        for (uint256 i = 0; i < _nTransfers; ++i) {
            uint256 _userId = i;
            address _token = address(m20[_amountPercentages[i] % m20.length]);
            _createTransferAction(users[_userId], _token, IERC20(_token).balanceOf(users[_userId]));
        }

        _shuffleActions();

        uint256 _totalGasUsed = _operatorExecute();

        string memory _snapId =
            string.concat("testFuzz_ERC20_MultipleTransfer:#Actions=", Strings.toString(_nTransfers));
        _snapshotGas(_snapId, _totalGasUsed, 1);
        vm.snapshotValue(string.concat(_snapId, ":AverageGasCostPerAction"), _totalGasUsed / _nTransfers);
    }
}
