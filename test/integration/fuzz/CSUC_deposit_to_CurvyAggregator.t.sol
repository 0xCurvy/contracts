// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";

import {Integration_BoilerPlate, Strings} from "../_BoilerPlate.t.sol";

import {CSUC, CSUC_Types, CSUC_Constants} from "../../../src/csuc/Exports.sol";
import {CurvyAggregator_Types, CurvyAggregator_Constants} from "../../../src/aggregator/Exports.sol";

import {MockERC20} from "../mocks/MockERC20.sol";

contract CSUC_to_CurvyAggregator_UnitTest is Integration_BoilerPlate {
    function setUp() public {
        Integration_BoilerPlate.basicSetUp();
    }

    function test_SingleERC20WrapFrom_CSUC_to_CurvyAggregator_UnitTest() public {
        address _from = users[0];
        (address _csa, uint256 _csaPk) = getUnusedCSA();
        MockERC20 _tokenHandler = m20[0];
        address _token = address(_tokenHandler);
        uint256 _amount = _tokenHandler.balanceOf(_from);

        // Deposit to CSUC
        _wrap(_from, _csa, _token, _amount);

        assertGt(_getCSUCBalance(_csa, _token), 0, "Balance should be greater than zero after wrap!");
        assertEq(csuc.nonceOf(_csa, _token), 0, "Nonce mismatch after single wrap!");

        // CSUC to CurvyAggregator
        _amount /= 3;

        CurvyAggregator_Types.Note[] memory _notes = new CurvyAggregator_Types.Note[](1);
        _notes[0] = CurvyAggregator_Types.Note({ownerHash: 0, token: uint256(uint160(_token)), amount: _amount});

        // Make the action active
        vm.roll(block.number + 1 + CSUC_Constants.ACTION_BECOMES_ACTIVE_AFTER_BLOCKS);

        bool _actionIsActive = csuc.actionIsActive(CurvyAggregator_Constants.CURVY_AGGREGATOR_CSUC_ACTION_HANDLER_ID);

        console.log("Action is active: %s", _actionIsActive ? "true" : "false");

        uint256 _totalFee =
            csuc.getMandatoryFee(CurvyAggregator_Constants.CURVY_AGGREGATOR_CSUC_ACTION_HANDLER_ID, _amount);

        console.log("Total fee for CSUC to CurvyAggregator action: %s", Strings.toString(_totalFee));
        CSUC_Types.ActionPayload memory _payload = CSUC_Types.ActionPayload({
            actionId: CurvyAggregator_Constants.CURVY_AGGREGATOR_CSUC_ACTION_HANDLER_ID,
            token: _token,
            amount: _amount,
            totalFee: _totalFee,
            limit: block.number + 1_000_000,
            parameters: abi.encode(_notes)
        });

        bytes32 _hash = csuc._hashActionPayload(_csa, _payload);

        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(_csaPk, _hash);

        CSUC_Types.Action[] memory _actions = new CSUC_Types.Action[](1);
        _actions[0] =
            CSUC_Types.Action({from: _csa, payload: _payload, signature_v: _v, signature_r: _r, signature_s: _s});

        uint256 _aggregatorBalanceBefore = _getBalance(address(aggregator), _token);

        vm.startBroadcast(operator);
        uint256 _actionsExecuted = csuc.operatorExecute(_actions);
        vm.stopBroadcast();

        assertEq(_actionsExecuted, 1, "Single action should be executed!");

        uint256 _aggregatorBalanceAfter = _getBalance(address(aggregator), _token);

        assertEq(_aggregatorBalanceAfter, _aggregatorBalanceBefore, "Aggregator balance should not change after wrap!");
    }

    function test_SingleNativeWrapFrom_CSUC_to_CurvyAggregator_UnitTest() public {
        address _from = users[0];
        (address _csa, uint256 _csaPk) = getUnusedCSA();
        address _token = CSUC_Constants.NATIVE_TOKEN;
        uint256 _amount = _from.balance / 2;

        // Deposit to CSUC
        _wrap(_from, _csa, _token, _amount);

        assertGt(_getCSUCBalance(_csa, _token), 0, "Balance should be greater than zero after wrap!");
        assertEq(csuc.nonceOf(_csa, _token), 0, "Nonce mismatch after single wrap!");

        // CSUC to CurvyAggregator
        _amount /= 3;

        CurvyAggregator_Types.Note[] memory _notes = new CurvyAggregator_Types.Note[](1);
        _notes[0] = CurvyAggregator_Types.Note({ownerHash: 0, token: uint256(uint160(_token)), amount: _amount});

        // Make the action active
        vm.roll(block.number + 1 + CSUC_Constants.ACTION_BECOMES_ACTIVE_AFTER_BLOCKS);

        bool _actionIsActive = csuc.actionIsActive(CurvyAggregator_Constants.CURVY_AGGREGATOR_CSUC_ACTION_HANDLER_ID);

        console.log("Action is active: %s", _actionIsActive ? "true" : "false");

        uint256 _totalFee =
            csuc.getMandatoryFee(CurvyAggregator_Constants.CURVY_AGGREGATOR_CSUC_ACTION_HANDLER_ID, _amount);

        console.log("Total fee for CSUC to CurvyAggregator action: %s", Strings.toString(_totalFee));
        CSUC_Types.ActionPayload memory _payload = CSUC_Types.ActionPayload({
            actionId: CurvyAggregator_Constants.CURVY_AGGREGATOR_CSUC_ACTION_HANDLER_ID,
            token: _token,
            amount: _amount,
            totalFee: _totalFee,
            limit: block.number + 1_000_000,
            parameters: abi.encode(_notes)
        });

        bytes32 _hash = csuc._hashActionPayload(_csa, _payload);

        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(_csaPk, _hash);

        CSUC_Types.Action[] memory _actions = new CSUC_Types.Action[](1);
        _actions[0] =
            CSUC_Types.Action({from: _csa, payload: _payload, signature_v: _v, signature_r: _r, signature_s: _s});

        uint256 _aggregatorBalanceBefore = _getBalance(address(aggregator), _token);

        vm.startBroadcast(operator);
        uint256 _actionsExecuted = csuc.operatorExecute(_actions);
        vm.stopBroadcast();

        assertEq(_actionsExecuted, 1, "Single action should be executed!");

        uint256 _aggregatorBalanceAfter = _getBalance(address(aggregator), _token);

        assertEq(_aggregatorBalanceAfter, _aggregatorBalanceBefore, "Aggregator balance should not change after wrap!");
    }
}
