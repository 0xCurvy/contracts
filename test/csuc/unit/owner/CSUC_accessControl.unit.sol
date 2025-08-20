// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {CSUC_BoilerPlate, Strings} from "../../_BoilerPlate.t.sol";

import {CSUC, CSUC_Types, CSUC_Constants, OwnableUpgradeable} from "../../../../src/csuc/CSUC.sol";

contract CSUC_owner_accessControl_UnitTest is CSUC_BoilerPlate {
    function setUp() public {
        CSUC_BoilerPlate.multipleSetUp();
    }

    function test_onlyOwnerCanUpdateConfig() public {
        address _newOperator = vm.randomAddress();

        CSUC_Types.ConfigUpdate memory _configUpdate = CSUC_Types.ConfigUpdate({
            newOperator: _newOperator,
            newFeeCollector: address(0),
            newAggregator: address(0),
            actionHandlingInfoUpdate: new CSUC_Types.ActionHandlingInfoUpdate[](0)
        });

        address _eoa = vm.randomAddress();

        vm.startBroadcast(_eoa);

        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, _eoa));
        csuc.updateConfig(_configUpdate);

        vm.stopBroadcast();
    }

    function test_onlyOwnerCanTransferOwnership() public {
        address _eoa = vm.randomAddress();
        address _newOwner = vm.randomAddress();

        vm.startBroadcast(_eoa);

        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, _eoa));
        csuc.transferOwnership(_newOwner);

        vm.stopBroadcast();

        vm.startBroadcast(owner);

        csuc.transferOwnership(_newOwner);

        vm.stopBroadcast();

        vm.startBroadcast(_newOwner);

        // csuc.acceptOwnership();

        vm.stopBroadcast();

        assertEq(csuc.owner(), _newOwner, "Ownership transfer failed!");
    }
}
