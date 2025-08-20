// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {CSUC, CSUC_Types, CSUC_Constants} from "../src/csuc/CSUC.sol";

contract CSUC_Deploy_Script is Script {
    function run() public {
        deployerPk = vm.envUint("DEPLOYER_PK");
        feeCollector = operator = vm.envAddress("OPERATOR_ADDR");

        vm.startBroadcast(deployerPk);

        address proxy = Upgrades.deployUUPSProxy("CSUC.sol", abi.encodeCall(CSUC.initialize, ()));
        csuc = CSUC(proxy);
        csuc.updateConfig(_buildConfig());

        console2.log("CSUC deployed at: ", address(csuc));

        string memory outputFile =
            string(abi.encodePacked("./deployments/", vm.envString("CHAIN_NAME"), "/CSUC.address"));
        vm.writeFile(outputFile, vm.toString(address(csuc)));

        vm.stopBroadcast();
    }

    function _buildConfig() internal returns (CSUC_Types.ConfigUpdate memory) {
        actionHandlingInfoUpdate.push(
            CSUC_Types.ActionHandlingInfoUpdate({
                actionId: CSUC_Constants.DEPOSIT_ACTION_ID,
                info: CSUC_Types.ActionHandlingInfo({
                    mandatoryFeePoints: uint16(0), // 0.0%
                    handler: CSUC_Constants.CORE_ACTION_HANDLER
                })
            })
        );

        actionHandlingInfoUpdate.push(
            CSUC_Types.ActionHandlingInfoUpdate({
                actionId: CSUC_Constants.TRANSFER_ACTION_ID,
                info: CSUC_Types.ActionHandlingInfo({
                    mandatoryFeePoints: uint16(CSUC_Constants.FEE_PRECISION / 1000), // 0.1%
                    handler: CSUC_Constants.CORE_ACTION_HANDLER
                })
            })
        );

        actionHandlingInfoUpdate.push(
            CSUC_Types.ActionHandlingInfoUpdate({
                actionId: CSUC_Constants.WITHDRAWAL_ACTION_ID,
                info: CSUC_Types.ActionHandlingInfo({
                    mandatoryFeePoints: uint16(8 * (CSUC_Constants.FEE_PRECISION / 1000)), // 0.8%
                    handler: CSUC_Constants.CORE_ACTION_HANDLER
                })
            })
        );

        CSUC_Types.ConfigUpdate memory _configUpdate = CSUC_Types.ConfigUpdate({
            newOperator: operator,
            newFeeCollector: feeCollector,
            newAggregator: address(0),
            actionHandlingInfoUpdate: actionHandlingInfoUpdate
        });

        return _configUpdate;
    }

    uint256 private deployerPk;
    address private operator;
    address private feeCollector;

    CSUC public csuc;
    CSUC_Types.ActionHandlingInfoUpdate[] actionHandlingInfoUpdate;
}
