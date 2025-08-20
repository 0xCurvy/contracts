// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {CSUC_BoilerPlate, Strings} from "../../_BoilerPlate.t.sol";

import {CSUC, CSUC_Types, CSUC_Constants, Ownable} from "../../../../src/csuc/Exports.sol";

contract CSUC_operator_accessControl_UnitTest is CSUC_BoilerPlate {
    function setUp() public {
        CSUC_BoilerPlate.multipleSetUp();
    }

    function test_onlyOperatorCanExecuteUserActions() public {
        CSUC_Types.Action[] memory _actions = new CSUC_Types.Action[](1);

        address _eoa = vm.randomAddress();

        vm.startBroadcast(_eoa);

        vm.expectRevert(bytes("CSUC: only operator can execute this call!"));
        csuc.operatorExecute(_actions);

        vm.stopBroadcast();

        vm.startBroadcast(operator);

        uint256 _actionsExecuted = csuc.operatorExecute(_actions);

        assertEq(_actionsExecuted, 0, "Operator should not be able to execute actions without valid actions!");

        vm.stopBroadcast();
    }
}
