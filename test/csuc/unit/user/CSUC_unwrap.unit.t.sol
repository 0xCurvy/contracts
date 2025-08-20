// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {CSUC_BoilerPlate, Strings} from "../../_BoilerPlate.t.sol";

import {CSUC, CSUC_Types, CSUC_Constants} from "../../../../src/csuc/CSUC.sol";

contract CSUC_unwrap_UnitTest is CSUC_BoilerPlate {
    function setUp() public {
        CSUC_BoilerPlate.multipleSetUp();
    }

    function test_Native_Unwrap() public {
        address _from = user_EOA_0;
        (address _csa, uint256 _csaPk) = getUnusedCSA();
        address _token = CSUC_Constants.NATIVE_TOKEN;
        uint256 _amount = _from.balance / 2;

        _wrap(_from, _csa, _token, _amount);

        assertGt(_getCSUCBalance(_csa, _token), 0, "Balance should be greater than zero after wrap!");
        assertEq(csuc.nonceOf(_csa, _token), 0, "Nonce mismatch after single wrap!");

        (address _to,) = getUnusedCSA();
        uint256 _withdrawAmount = _getCSUCBalance(_csa, _token) / 3;
        uint256 _totalFee = csuc.getMandatoryFee(CSUC_Constants.WITHDRAWAL_ACTION_ID, _withdrawAmount);

        CSUC_Types.Action memory _action = _prepareWithdrawAction(_csa, _csaPk, _to, _token, _withdrawAmount, _totalFee);

        vm.startBroadcast(users[0]);
        csuc.unwrap(_action);
        vm.stopBroadcast();

        assertGt(_getCSUCBalance(_csa, _token), 0, "Balance should be greater than zero after unwrap!");
        assertEq(csuc.nonceOf(_csa, _token), 1, "Nonce mismatch after single unwrap!");
    }

    function test_ERC20_Unwrap() public {
        for (uint256 i = 0; i < m20.length; ++i) {
            address _from = users[i % users.length];
            (address _csa, uint256 _csaPk) = getUnusedCSA();
            address _token = CSUC_Constants.NATIVE_TOKEN;
            uint256 _amount = _from.balance / 2;

            _wrap(_from, _csa, _token, _amount);

            assertGt(_getCSUCBalance(_csa, _token), 0, "Balance should be greater than zero after wrap!");
            assertEq(csuc.nonceOf(_csa, _token), 0, "Nonce mismatch after single wrap!");

            (address _to,) = getUnusedCSA();
            uint256 _withdrawAmount = _getCSUCBalance(_csa, _token) / 3;
            uint256 _totalFee = csuc.getMandatoryFee(CSUC_Constants.WITHDRAWAL_ACTION_ID, _withdrawAmount);

            CSUC_Types.Action memory _action =
                _prepareWithdrawAction(_csa, _csaPk, _to, _token, _withdrawAmount, _totalFee);

            vm.startBroadcast(_from);
            csuc.unwrap(_action);
            vm.stopBroadcast();

            assertGt(_getCSUCBalance(_csa, _token), 0, "Balance should be greater than zero after unwrap!");
            assertEq(csuc.nonceOf(_csa, _token), 1, "Nonce mismatch after single unwrap!");
        }
    }
}
