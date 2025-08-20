// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {CSUC_BoilerPlate, Strings} from "../../_BoilerPlate.t.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {CSUC, CSUC_Types, CSUC_Constants} from "../../../../src/csuc/CSUC.sol";

contract CSUC_operatorExecute_ERC20_Mix_FuzzTest is CSUC_BoilerPlate {
    function setUp() public {
        CSUC_BoilerPlate.multipleSetUp();
    }

    function testFuzz_ERC20_SingleMix(uint256 _userId, uint256 _tokenId, uint256 _amountPercentage) public {
        // Transfer Action
        _userId %= users.length;
        _amountPercentage = 1 + (_amountPercentage) % 100;
        address _token = address(m20[_tokenId % m20.length]);

        uint256 _transferAmount = (_amountPercentage * IERC20(_token).balanceOf(users[_userId])) / 100;

        _createTransferAction(users[_userId], _token, _transferAmount);

        // Withdraw Action
        address _from = users[(1 + _userId) % users.length];
        (address _csa, uint256 _csaPk) = getUnusedCSA();
        uint256 _withdrawalAmount = (_amountPercentage * IERC20(_token).balanceOf(_from)) / 100;

        _wrap(_from, _csa, _token, _withdrawalAmount);

        (address _to,) = getUnusedCSA();
        usedCSA.push(_to);
        m20BalancesBeforeWithdraw[_token][_to] = _to.balance;

        _createWithdrawAction(_csa, _csaPk, _to, _token, _withdrawalAmount / 3);

        m20WithdrawAmounts[_token][_to] = _withdrawalAmount / 3;

        _shuffleActions();
        _operatorExecute();

        assertEq(IERC20(_token).balanceOf(usedCSA[0]), m20WithdrawAmounts[_token][usedCSA[0]]);
    }

    function testFuzz_ERC20_MultipleMix(uint256[] memory _amountPercentages) public {
        vm.assume(_amountPercentages.length > 0 && _amountPercentages.length <= 10);

        // Transfer Actions
        uint256 _nTransfers = _amountPercentages.length;

        for (uint256 i = 0; i < _nTransfers; ++i) {
            address _from = users[i];
            address _token = address(m20[i % m20.length]);
            uint256 _amountPercentage = _amountPercentages[i] % 100;
            uint256 _amount = 1 + (_amountPercentage * IERC20(_token).balanceOf(_from)) / 100;
            _createTransferAction(_from, _token, _amount);
        }

        // Withdraw Actions
        uint256 _nWithdrawals = _nTransfers;
        for (uint256 i = 0; i < _nWithdrawals; ++i) {
            address _from = users[i];
            address _token = address(m20[i * _nWithdrawals * 13 % m20.length]);
            (address _csa, uint256 _csaPk) = getUnusedCSA();
            uint256 _amount = 1 + ((1 + _nWithdrawals * i % 100) * IERC20(_token).balanceOf(_from)) / 100;
            _wrap(_from, _csa, _token, _amount);

            (address _to,) = getUnusedCSA();
            usedCSA.push(_to);
            m20BalancesBeforeWithdraw[_token][_to] = _to.balance;

            _createWithdrawAction(_csa, _csaPk, _to, _token, _amount / 2);

            m20WithdrawAmounts[_token][_to] = _amount / 2;
            usedToken.push(_token);
        }

        _shuffleActions();
        _operatorExecute();

        for (uint256 i = 0; i < _nWithdrawals; ++i) {
            assertEq(IERC20(usedToken[i]).balanceOf(usedCSA[i]), m20WithdrawAmounts[usedToken[i]][usedCSA[i]]);
        }
    }
}
