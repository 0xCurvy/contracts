// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Script, console2} from "forge-std/Script.sol";
import {CSUC, CSUC_Types, CSUC_Constants} from "../src/csuc/CSUC.sol";
import {
    CurvyAggregator_NoAssetTransfer_TmpUpgrade,
    CurvyAggregator_Types,
    CurvyAggregator_Constants
} from "../src/aggregator/CurvyAggregator_NoAssetTransfer_TmpUpgrade.sol";
import {
    ICSUC_ActionHandler,
    CurvyAggregator_CSUC_NoAssetTransfer_ActionHandler
} from "../src/aggregator/csuc_action_handler/CurvyAggregator_CSUC_NoAssetTransfer_ActionHandler.sol";

contract Integration_Deposit_To_Aggregator_From_CSUC_Script is Script {
    function run() public {
        deployerPk = vm.envUint("DEPLOYER_PK");

        vm.startBroadcast(deployerPk);

        aggregator = CurvyAggregator_NoAssetTransfer_TmpUpgrade(
            vm.parseAddress(
                vm.readFile(
                    string(abi.encodePacked("./deployments/", vm.envString("CHAIN_NAME"), "/CurvyAggregator.address"))
                )
            )
        );
        csuc = CSUC(
            vm.parseAddress(
                vm.readFile(string(abi.encodePacked("./deployments/", vm.envString("CHAIN_NAME"), "/CSUC.address")))
            )
        );

        actionHandler = new CurvyAggregator_CSUC_NoAssetTransfer_ActionHandler();

        console2.log("CurvyAggregator_CSUC_NoAssetTransfer_ActionHandler deployed at: ", address(actionHandler));
        vm.writeFile(
            string(
                abi.encodePacked(
                    "./deployments/", vm.envString("CHAIN_NAME"), "/CurvyAggregator_CSUC_ActionHandler.address"
                )
            ),
            vm.toString(address(actionHandler))
        );

        CSUC_Types.ActionHandlingInfoUpdate[] memory actionHandlingInfoUpdate =
            new CSUC_Types.ActionHandlingInfoUpdate[](1);
        actionHandlingInfoUpdate[0] = CSUC_Types.ActionHandlingInfoUpdate({
            actionId: CurvyAggregator_Constants.CURVY_AGGREGATOR_CSUC_ACTION_HANDLER_ID,
            info: CSUC_Types.ActionHandlingInfo({mandatoryFeePoints: uint16(0), handler: address(actionHandler)})
        });

        csuc.updateConfig(
            CSUC_Types.ConfigUpdate({
                newOperator: address(0),
                newFeeCollector: address(0),
                newAggregator: address(aggregator),
                actionHandlingInfoUpdate: actionHandlingInfoUpdate
            })
        );

        vm.stopBroadcast();
    }

    uint256 private deployerPk;
    uint256 private operatorPk;
    address private operator;
    address private feeCollector;

    CSUC public csuc;
    CurvyAggregator_NoAssetTransfer_TmpUpgrade public aggregator;
    CurvyAggregator_CSUC_NoAssetTransfer_ActionHandler public actionHandler;
}
