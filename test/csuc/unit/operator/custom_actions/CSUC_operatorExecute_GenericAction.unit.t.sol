// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {CSUC_BoilerPlate, Strings} from "../../../_BoilerPlate.t.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {CSUC, CSUC_Types, CSUC_Constants} from "../../../../../src/csuc/CSUC.sol";

contract CSUC_operatorExecute_GenericAction_UnitTest is CSUC_BoilerPlate {
    function setUp() public {
        CSUC_BoilerPlate.multipleSetUp();
    }

    function test_SingleGenericAction() public {
        (uint256 _mandatoryFeePoints, address _handler) = csuc.actionInfo(CSUC_Constants.GENERIC_CUSTOM_ACTION_ID);

        assertGt(_mandatoryFeePoints, 0, "Mandatory fee points mismatch!");
        assertEq(_handler != address(0), true, "Action handler is not set!");

        address _from = users[0];
        address _token = CSUC_Constants.NATIVE_TOKEN;
        uint256 _amount = _getBalance(_from, _token) / 4;

        (address _csa, uint256 _csaPk) = getUnusedCSA();
        _wrap(_from, _csa, _token, _amount);

        (address _to,) = getUnusedCSA();
        uint256 _genericActionAmount = _getCSUCBalance(_csa, _token) / 3;
        uint256 _totalFee = csuc.getMandatoryFee(CSUC_Constants.GENERIC_CUSTOM_ACTION_ID, _genericActionAmount);

        CSUC_Types.ActionPayload memory _payload = CSUC_Types.ActionPayload({
            actionId: CSUC_Constants.GENERIC_CUSTOM_ACTION_ID,
            token: _token,
            amount: _genericActionAmount,
            parameters: abi.encode(_to),
            totalFee: _totalFee,
            limit: block.number + CSUC_Constants.ACTION_BECOMES_ACTIVE_AFTER_BLOCKS + 10
        });

        bytes32 _hash = csuc._hashActionPayload(_csa, _payload);

        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(_csaPk, _hash);

        CSUC_Types.Action memory _action =
            CSUC_Types.Action({from: _csa, payload: _payload, signature_v: _v, signature_r: _r, signature_s: _s});

        delete actions;
        actions.push(_action);
        _shuffleActions();

        (, uint256 _actionsExecuted) = _operatorExecuteWithReturn();
        assertEq(_actionsExecuted, 0, "Expected 0 action to be executed");
        assertEq(csuc.nonceOf(_csa, _action.payload.token), 0);

        // note: `GENERIC_CUSTOM_ACTION_ID` needs to become active for it to be executed
        vm.roll(block.number + CSUC_Constants.ACTION_BECOMES_ACTIVE_AFTER_BLOCKS);
        (, _actionsExecuted) = _operatorExecuteWithReturn();

        assertEq(_actionsExecuted, 1, "Expected 1 action to be executed");
        assertEq(csuc.nonceOf(_csa, _action.payload.token), 1);
    }

    function test_MultipleGenericAction() public {
        (uint256 _mandatoryFeePoints, address _handler) = csuc.actionInfo(CSUC_Constants.GENERIC_CUSTOM_ACTION_ID);

        assertGt(_mandatoryFeePoints, 0, "Mandatory fee points mismatch!");
        assertEq(_handler != address(0), true, "Action handler is not set!");

        address _token = CSUC_Constants.NATIVE_TOKEN;

        // Prepare actions from different users
        uint256 N_ACTIONS = 5;
        delete actions;
        for (uint256 i = 0; i < N_ACTIONS; ++i) {
            address _from = users[i];
            uint256 _amount = _getBalance(_from, _token) / 11;

            (address _csa, uint256 _csaPk) = getUnusedCSA();
            _wrap(_from, _csa, _token, _amount);

            (address _to,) = getUnusedCSA();
            uint256 _genericActionAmount = _getCSUCBalance(_csa, _token) / (i + 3);
            uint256 _totalFee = csuc.getMandatoryFee(CSUC_Constants.GENERIC_CUSTOM_ACTION_ID, _genericActionAmount);

            CSUC_Types.ActionPayload memory _payload = CSUC_Types.ActionPayload({
                actionId: CSUC_Constants.GENERIC_CUSTOM_ACTION_ID,
                token: _token,
                amount: _genericActionAmount,
                parameters: abi.encode(_to),
                totalFee: _totalFee,
                limit: block.number + CSUC_Constants.ACTION_BECOMES_ACTIVE_AFTER_BLOCKS + 10
            });

            bytes32 _hash = csuc._hashActionPayload(_csa, _payload);

            (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(_csaPk, _hash);

            CSUC_Types.Action memory _action =
                CSUC_Types.Action({from: _csa, payload: _payload, signature_v: _v, signature_r: _r, signature_s: _s});

            actions.push(_action);
        }
        _shuffleActions();

        (, uint256 _actionsExecuted) = _operatorExecuteWithReturn();
        assertEq(_actionsExecuted, 0, "Expected 0 action to be executed!");
        // Check there were no changes made
        for (uint256 i = 0; i < N_ACTIONS; ++i) {
            CSUC_Types.Action memory _action = actions[i];
            address _csa = _action.from;
            assertEq(_action.payload.token, CSUC_Constants.NATIVE_TOKEN, "Token mismatch!");
            assertEq(csuc.nonceOf(_csa, _action.payload.token), 0);
        }

        // note: `GENERIC_CUSTOM_ACTION_ID` needs to become active for it to be executed
        vm.roll(block.number + CSUC_Constants.ACTION_BECOMES_ACTIVE_AFTER_BLOCKS);
        (, _actionsExecuted) = _operatorExecuteWithReturn();

        assertEq(_actionsExecuted, N_ACTIONS, "Expected `N_ACTIONS` to be executed!");

        // Check balances and nonces
        for (uint256 i = 0; i < N_ACTIONS; ++i) {
            CSUC_Types.Action memory _action = actions[i];
            address _csa = _action.from;
            assertEq(_action.payload.token, CSUC_Constants.NATIVE_TOKEN, "Token mismatch!");
            assertEq(_action.payload.amount, _getCSUCBalance(_csa, _action.payload.token) / (i + 3), "Amount mismatch!");
            assertEq(csuc.nonceOf(_csa, _action.payload.token), 1);
        }
    }
}
