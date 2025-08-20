// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {CSUC_BoilerPlate, Strings} from "../../_BoilerPlate.t.sol";

import {CSUC, CSUC_Types, CSUC_Constants} from "../../../../src/csuc/CSUC.sol";

contract CSUC_wrap_UnitTest is CSUC_BoilerPlate {
    function setUp() public {
        CSUC_BoilerPlate.multipleSetUp();
    }

    function test_Native_SingleWrap() public {
        uint256 _totalGasUsed = 0;

        address _from = user_EOA_0;
        address _to = CSA_0;
        address _token = CSUC_Constants.NATIVE_TOKEN;
        uint256 _amount = _from.balance / 2;

        _totalGasUsed += _wrap(_from, _to, _token, _amount);

        assertGt(_getCSUCBalance(_to, _token), 0, "Balance should be greater than zero after wrap!");
        assertEq(csuc.nonceOf(_to, _token), 0, "Nonce mismatch after single wrap!");

        uint256 _n = 1;
        string memory _snapId = string.concat("test_Native_SingleWrap:#Actions=", Strings.toString(_n));
        _snapshotGas(_snapId, _totalGasUsed, 1);
    }

    function test_Native_MultipleSingleWraps() public {
        uint256 _totalGasUsed = 0;

        uint256 _repetitions = 3;
        for (uint256 j = 0; j < _repetitions; ++j) {
            for (uint256 i = 0; i < users.length; ++i) {
                address _from = users[i];
                (address _to,) = getUnusedCSA();
                address _token = CSUC_Constants.NATIVE_TOKEN;
                uint256 _amount = _from.balance / 2;

                _totalGasUsed += _wrap(_from, _to, _token, _amount);

                assertGt(_getCSUCBalance(_to, _token), 0, "Balance should be greater than zero after wrap!");
                assertEq(csuc.nonceOf(_to, _token), 0, "Nonce mismatch after multiple single wraps!");
            }
        }

        uint256 _n = _repetitions * users.length;
        string memory _snapId = string.concat("test_Native_MultipleSingleWraps:#Actions=", Strings.toString(_n));
        _snapshotGas(_snapId, _totalGasUsed, _n);
    }

    function test_ERC20_SingleWrap() public {
        uint256 _totalGasUsed = 0;

        address _from = user_EOA_0;
        address _to = CSA_0;
        address _token = address(m20[0]);
        uint256 _amount = m20[0].balanceOf(_from);

        _totalGasUsed += _wrap(_from, _to, _token, _amount);

        assertGt(_getCSUCBalance(_to, _token), 0, "Balance should be greater than zero after wrap!");
        assertEq(csuc.nonceOf(_to, _token), 0, "Nonce mismatch after multiple single wraps!");

        uint256 _n = 1 * users.length * m20.length;
        string memory _snapId = string.concat("test_ERC20_SingleWrap:#Actions=", Strings.toString(_n));
        _snapshotGas(_snapId, _totalGasUsed, _n);
    }

    function test_ERC20_MultipleSingleWraps() public {
        uint256 _totalGasUsed = 0;

        uint256 _repetitions = 3;
        for (uint256 k = 0; k < _repetitions; ++k) {
            for (uint256 i = 0; i < users.length; ++i) {
                for (uint256 j = 0; j < m20.length; ++j) {
                    address _from = users[i];
                    (address _to,) = getUnusedCSA();
                    address _token = address(m20[j]);
                    uint256 _amount = m20[j].balanceOf(_from) / 2;

                    _totalGasUsed += _wrap(_from, _to, _token, _amount);

                    assertGt(_getCSUCBalance(_to, _token), 0, "Balance should be greater than zero after wrap!");
                    assertEq(csuc.nonceOf(_to, _token), 0, "Nonce mismatch after multiple single wraps!");
                }
            }
        }

        uint256 _n = _repetitions * users.length * m20.length;
        string memory _snapId = string.concat("test_ERC20_MultipleSingleWraps:#Actions=", Strings.toString(_n));
        _snapshotGas(_snapId, _totalGasUsed, _n);
    }
}
