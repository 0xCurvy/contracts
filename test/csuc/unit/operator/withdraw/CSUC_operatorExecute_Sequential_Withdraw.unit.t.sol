// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {CSUC_BoilerPlate, Strings} from "../../../_BoilerPlate.t.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {CSUC, CSUC_Types, CSUC_Constants} from "../../../../../src/csuc/CSUC.sol";

contract CSUC_operatorExecute_Sequential_Withdraw_UnitTest is CSUC_BoilerPlate {
    function setUp() public {
        CSUC_BoilerPlate.multipleSetUp();
    }

    function test_All_Sequential_MultipleWithdraw() public {
        uint256 _nTransfers = users.length;

        address[] memory _csas = new address[](_nTransfers);
        uint256[] memory _csaPks = new uint256[](_nTransfers);

        uint256 N_ACTIONS = 13;

        for (uint256 i = 0; i < _nTransfers; ++i) {
            (address __csa, uint256 __csaPk) = getUnusedCSA();
            uint256 _amount = (_getBalance(users[i], _token(i)) / 3) + 1; // Ensure non-zero amount
            _wrap(users[i], __csa, _token(i), _amount);
            _csas[i] = __csa;
            _csaPks[i] = __csaPk;
        }

        for (uint256 _expectedNonce = 1; _expectedNonce < N_ACTIONS; ++_expectedNonce) {
            for (uint256 i = 0; i < _nTransfers; ++i) {
                address _csa = _csas[i];
                uint256 _csaPk = _csaPks[i];
                (address _to,) = getUnusedCSA();
                uint256 _withdrawAmount = _getCSUCBalance(_csa, _token(i)) / 3;
                uint256 _totalFee = csuc.getMandatoryFee(CSUC_Constants.WITHDRAWAL_ACTION_ID, _withdrawAmount);

                CSUC_Types.Action memory _action =
                    _prepareWithdrawAction(_csa, _csaPk, _to, _token(i), _withdrawAmount, _totalFee);

                actions.push(_action);
            }

            _shuffleActions();
            _operatorExecute();
            delete actions;

            for (uint256 i = 0; i < _nTransfers; ++i) {
                assertEq(csuc.nonceOf(_csas[i], _token(i)), _expectedNonce, "Nonce mismatch!");
            }
        }
    }

    function _token(uint256 _i) internal view returns (address) {
        if (_i % 3 == 0) {
            return CSUC_Constants.NATIVE_TOKEN;
        }
        return address(m20[_i % m20.length]);
    }
}
