// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";

import {Options} from "openzeppelin-foundry-upgrades/Options.sol";

import {CSUC_BoilerPlate, Strings, Upgrades} from "../_BoilerPlate.t.sol";

import {CSUC, CSUC_Types, CSUC_Constants, OwnableUpgradeable} from "../../../src/csuc/CSUC.sol";

import {CSUC_FutureVersion} from "./CSUC_FutureVersion.sol";

contract CSUC_UpgradeTest is CSUC_BoilerPlate {
    function setUp() public {
        CSUC_BoilerPlate.multipleSetUp();

        proxyAddress = address(csuc);
    }

    function test_OwnerCanUpgrade() public {
        vm.startBroadcast(owner);

        Upgrades.upgradeProxy(
            proxyAddress, "CSUC_FutureVersion.sol", abi.encodeCall(CSUC_FutureVersion.setSomethingNew, (SOME_NEW_VALUE))
        );

        CSUC_FutureVersion _upgradedCSUC = CSUC_FutureVersion(proxyAddress);

        assertEq(
            _upgradedCSUC.getSomethingNew(),
            SOME_NEW_VALUE,
            "Value mismatch in CSUC_FutureVersion: getSomethingNew != SOME_NEW_VALUE!"
        );

        vm.stopBroadcast();
    }

    function testFuzz_NonOwnerCannotUpgrade(address _nonOwner) public {
        vm.assume(_nonOwner != owner);

        vm.startBroadcast(_nonOwner);

        // Options memory _options;

        // TODO: find a way to test access control on upgrade, and catch the exact revert reason
        // vm.expectRevert();
        // Upgrades.prepareUpgrade("CSUC_FutureVersion.sol", _options);

        vm.stopBroadcast();
    }

    address public proxyAddress;

    uint256 public constant SOME_NEW_VALUE = 42;
}
