// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {CSUC_BoilerPlate, Strings} from "../../_BoilerPlate.t.sol";

import {CSUC, CSUC_Types, CSUC_Constants} from "../../../../src/csuc/CSUC.sol";

contract CSUC_updateConfig_UnitTest is CSUC_BoilerPlate {
    function setUp() public {
        CSUC_BoilerPlate.multipleSetUp();
    }

    function test_Config_ValidOperatorUpdate() public {
        address _newOperator = vm.randomAddress();
        address _currentFeeCollector = csuc.feeCollector();

        CSUC_Types.ConfigUpdate memory _configUpdate = CSUC_Types.ConfigUpdate({
            newOperator: _newOperator,
            newFeeCollector: address(0),
            newAggregator: address(0),
            actionHandlingInfoUpdate: new CSUC_Types.ActionHandlingInfoUpdate[](0)
        });

        vm.startBroadcast(owner);

        csuc.updateConfig(_configUpdate);

        vm.stopBroadcast();

        assertEq(csuc.operator(), _newOperator, "Update operator failed!");
        assertEq(csuc.feeCollector(), _currentFeeCollector, "Fee collector should not change!");
    }

    function test_Config_ValidFeeCollectorUpdate() public {
        address _newFeeCollector = vm.randomAddress();
        address _currentOperator = csuc.operator();

        CSUC_Types.ConfigUpdate memory _configUpdate = CSUC_Types.ConfigUpdate({
            newOperator: address(0),
            newFeeCollector: _newFeeCollector,
            newAggregator: address(0),
            actionHandlingInfoUpdate: new CSUC_Types.ActionHandlingInfoUpdate[](0)
        });

        vm.startBroadcast(owner);

        csuc.updateConfig(_configUpdate);

        vm.stopBroadcast();

        assertEq(csuc.operator(), _currentOperator, "Operator should not change!");
        assertEq(csuc.feeCollector(), _newFeeCollector, "Fee collector should change!");
    }

    function test_Config_ValidActionHandlerUpdate() public {
        address _currentFeeCollector = csuc.feeCollector();
        address _currentOperator = csuc.operator();

        uint256[] memory _actionIds = new uint256[](3);
        _actionIds[0] = CSUC_Constants.DEPOSIT_ACTION_ID;
        _actionIds[1] = CSUC_Constants.TRANSFER_ACTION_ID;
        _actionIds[2] = CSUC_Constants.WITHDRAWAL_ACTION_ID;

        for (uint256 i = 0; i < _actionIds.length; ++i) {
            uint256[] memory _oldFeePoints = new uint256[](_actionIds.length);
            for (uint256 j = 0; j < _actionIds.length; ++j) {
                _oldFeePoints[j] = csuc.getActionHandlingInfo(_actionIds[j]).mandatoryFeePoints;
            }

            uint16 _updatedPoints = uint16(_oldFeePoints[i] + 1);

            CSUC_Types.ActionHandlingInfoUpdate[] memory _actionUpdates = new CSUC_Types.ActionHandlingInfoUpdate[](1);

            _actionUpdates[0] = CSUC_Types.ActionHandlingInfoUpdate({
                actionId: _actionIds[i],
                info: CSUC_Types.ActionHandlingInfo({
                    mandatoryFeePoints: _updatedPoints,
                    handler: CSUC_Constants.CORE_ACTION_HANDLER
                })
            });

            CSUC_Types.ConfigUpdate memory _configUpdate = CSUC_Types.ConfigUpdate({
                newOperator: address(0),
                newFeeCollector: address(0),
                newAggregator: address(0),
                actionHandlingInfoUpdate: _actionUpdates
            });

            vm.startBroadcast(owner);

            csuc.updateConfig(_configUpdate);

            vm.stopBroadcast();

            assertEq(
                csuc.getActionHandlingInfo(_actionIds[i]).mandatoryFeePoints,
                _updatedPoints,
                "Action handling info update failed!"
            );

            uint256[] memory _newFeePoints = new uint256[](_actionIds.length);
            for (uint256 j = 0; j < _actionIds.length; ++j) {
                _newFeePoints[j] = csuc.getActionHandlingInfo(_actionIds[j]).mandatoryFeePoints;
                if (i != j) {
                    assertEq(_newFeePoints[j], _oldFeePoints[j], "Other action handling info should not change!");
                }
            }

            assertEq(csuc.operator(), _currentOperator, "Operator should not change!");
            assertEq(csuc.feeCollector(), _currentFeeCollector, "Fee collector should not change!");
        }
    }
}
