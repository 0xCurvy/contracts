// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Script, console2} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {CSUC_TmpUpgrade, CSUC_Types, CSUC_Constants} from "../../src/csuc/CSUC_TmpUpgrade.sol";
import {
    CurvyAggregator_NoAssetTransfer_TmpUpgrade,
    CurvyAggregator_Types
} from "../../src/aggregator/CurvyAggregator_NoAssetTransfer_TmpUpgrade.sol";

contract UpgradeAll_Script is Script {
    function run() public {
        deployerPk = vm.envUint("DEPLOYER_PK");
        feeCollector = operator = vm.envAddress("OPERATOR_ADDR");

        vm.startBroadcast(deployerPk);

        address _proxyCSUC = vm.parseAddress(
            vm.readFile(string(abi.encodePacked("./deployments/", vm.envString("CHAIN_NAME"), "/CSUC.address")))
        );

        Upgrades.upgradeProxy(_proxyCSUC, "CSUC_TmpUpgrade.sol", abi.encodeCall(CSUC_TmpUpgrade.actionIsActive, (0)));

        address _aggregatorProxy = vm.parseAddress(
            vm.readFile(
                string(abi.encodePacked("./deployments/", vm.envString("CHAIN_NAME"), "/CurvyAggregator.address"))
            )
        );

        Upgrades.upgradeProxy(
            _aggregatorProxy,
            "CurvyAggregator_NoAssetTransfer_TmpUpgrade.sol",
            abi.encodeCall(CurvyAggregator_NoAssetTransfer_TmpUpgrade.noteTree, ())
        );

        CurvyAggregator_Types.ConfigurationUpdate memory _aggregatorConfig = CurvyAggregator_Types.ConfigurationUpdate({
            insertionVerifier: address(0),
            aggregationVerifier: address(0),
            withdrawVerifier: address(0),
            operator: address(0),
            csuc: address(0),
            feeCollector: address(0),
            withdrawBps: 10
        });

        CurvyAggregator_NoAssetTransfer_TmpUpgrade(_aggregatorProxy).updateConfig(_aggregatorConfig);

        vm.stopBroadcast();
    }

    uint256 private deployerPk;
    address private operator;
    address private feeCollector;

    CSUC_TmpUpgrade public csuc;
    CSUC_Types.ActionHandlingInfoUpdate[] actionHandlingInfoUpdate;
}
