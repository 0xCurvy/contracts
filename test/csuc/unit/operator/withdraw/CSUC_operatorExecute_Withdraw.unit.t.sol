// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {CSUC_BoilerPlate, IERC20, Strings} from "../../../_BoilerPlate.t.sol";

import {CSUC, CSUC_Types, CSUC_Constants} from "../../../../../src/csuc/CSUC.sol";

contract CSUC_operatorExecute_Withdraw_UnitTest is Test, CSUC_BoilerPlate {
    function setUp() public {
        CSUC_BoilerPlate.multipleSetUp();
    }

    function test_Native_SingleWithdraw() public {
        address _from = users[0];
        (address _csa, uint256 _csaPk) = getUnusedCSA();
        address _token = CSUC_Constants.NATIVE_TOKEN;
        uint256 _amount = _from.balance / 2;
        _wrap(_from, _csa, _token, _amount);

        (address _to,) = getUnusedCSA();
        usedCSA.push(_to);
        m20BalancesBeforeWithdraw[_token][_to] = _to.balance;

        _createWithdrawAction(_csa, _csaPk, _to, _token, _amount / 3);

        m20WithdrawAmounts[_token][_to] = _amount / 3;

        uint256 _totalGasUsed = _operatorExecute();

        assertEq(usedCSA[0].balance, m20WithdrawAmounts[_token][usedCSA[0]]);

        uint256 _nWithdrawals = 1;
        string memory _snapId = string.concat("test_Native_SingleWithdraw:#Actions=", Strings.toString(_nWithdrawals));
        _snapshotGas(_snapId, _totalGasUsed, 1);
        vm.snapshotValue(string.concat(_snapId, ":AverageGasCostPerAction"), _totalGasUsed / _nWithdrawals);
    }

    function test_Native_MultipleWithdraw() public {
        address _token = CSUC_Constants.NATIVE_TOKEN;

        for (uint256 i = 0; i < users.length; ++i) {
            address _from = users[i];
            (address _csa, uint256 _csaPk) = getUnusedCSA();
            uint256 _amount = _from.balance / 2;
            _wrap(_from, _csa, _token, _amount);

            (address _to,) = getUnusedCSA();
            usedCSA.push(_to);
            m20BalancesBeforeWithdraw[_token][_to] = _to.balance;

            _createWithdrawAction(_csa, _csaPk, _to, _token, _amount / 2);

            m20WithdrawAmounts[_token][_to] = _amount / 2;
        }

        uint256 _totalGasUsed = _operatorExecute();

        for (uint256 i = 0; i < usedCSA.length; ++i) {
            assertEq(usedCSA[i].balance, m20WithdrawAmounts[_token][usedCSA[i]]);
        }

        uint256 _nWithdrawals = usedCSA.length;
        string memory _snapId = string.concat("test_Native_MultipleWithdraw:#Actions=", Strings.toString(_nWithdrawals));
        _snapshotGas(_snapId, _totalGasUsed, 1);
        vm.snapshotValue(string.concat(_snapId, ":AverageGasCostPerAction"), _totalGasUsed / _nWithdrawals);
    }

    function test_ERC20_SingleWithdraw() public {
        address _from = users[0];
        (address _csa, uint256 _csaPk) = getUnusedCSA();
        address _token = address(m20[0]);
        uint256 _amount = IERC20(_token).balanceOf(_from);
        _wrap(_from, _csa, _token, _amount);

        (address _to,) = getUnusedCSA();
        usedCSA.push(_to);
        m20BalancesBeforeWithdraw[_token][_to] = IERC20(_token).balanceOf(_to);

        _createWithdrawAction(_csa, _csaPk, _to, _token, _amount / 3);

        m20WithdrawAmounts[_token][_to] = _amount / 3;

        uint256 _totalGasUsed = _operatorExecute();

        assertEq(IERC20(_token).balanceOf(usedCSA[0]), m20WithdrawAmounts[_token][usedCSA[0]]);

        uint256 _nWithdrawals = usedCSA.length;
        string memory _snapId = string.concat("test_ERC20_SingleWithdraw:#Actions=", Strings.toString(_nWithdrawals));
        _snapshotGas(_snapId, _totalGasUsed, 1);
        vm.snapshotValue(string.concat(_snapId, ":AverageGasCostPerAction"), _totalGasUsed / _nWithdrawals);
    }

    function test_ERC20_MultipleWithdraw() public {
        for (uint256 i = 0; i < users.length; ++i) {
            address _from = users[i];
            (address _csa, uint256 _csaPk) = getUnusedCSA();
            address _token = address(m20[i % m20.length]);
            uint256 _amount = IERC20(_token).balanceOf(_from);
            _wrap(_from, _csa, _token, _amount);

            (address _to,) = getUnusedCSA();
            usedCSA.push(_to);
            m20BalancesBeforeWithdraw[_token][_to] = IERC20(_token).balanceOf(_to);

            _createWithdrawAction(_csa, _csaPk, _to, _token, _amount / 3);

            m20WithdrawAmounts[_token][_to] = _amount / 3;
            usedToken.push(_token);
        }

        uint256 _totalGasUsed = _operatorExecute();

        for (uint256 i = 0; i < usedCSA.length; ++i) {
            assertEq(IERC20(usedToken[i]).balanceOf(usedCSA[i]), m20WithdrawAmounts[usedToken[i]][usedCSA[i]]);
        }

        uint256 _nWithdrawals = usedCSA.length;
        string memory _snapId = string.concat("test_ERC20_MultipleWithdraw:#Actions=", Strings.toString(_nWithdrawals));
        _snapshotGas(_snapId, _totalGasUsed, 1);
        vm.snapshotValue(string.concat(_snapId, ":AverageGasCostPerAction"), _totalGasUsed / _nWithdrawals);
    }
}
