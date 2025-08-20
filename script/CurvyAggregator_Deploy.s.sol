// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {Script, console2} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {
    CurvyAggregator, CurvyAggregator_Types, CurvyAggregator_Constants
} from "../src/aggregator/CurvyAggregator.sol";

contract CurvyAggregator_Deploy_Script is Script {
    function run() public {
        deployerPk = vm.envUint("DEPLOYER_PK");
        operatorPk = vm.envUint("OPERATOR_PK");
        feeCollector = operator = vm.envAddress("OPERATOR_ADDR");

        vm.startBroadcast(deployerPk);

        address proxy = Upgrades.deployUUPSProxy("CurvyAggregator.sol", abi.encodeCall(CurvyAggregator.initialize, ()));
        aggregator = CurvyAggregator(proxy);

        aggregator.updateConfig(_buildConfig());
        console2.log("CurvyAggregator deployed at: ", address(aggregator));

        string memory outputFile =
            string(abi.encodePacked("./deployments/", vm.envString("CHAIN_NAME"), "/CurvyAggregator.address"));
        vm.writeFile(outputFile, vm.toString(address(aggregator)));

        vm.stopBroadcast();
    }

    function _buildConfig() internal view returns (CurvyAggregator_Types.ConfigurationUpdate memory _configUpdate) {
        // Note: Verifiers are deployed in a separate script
        _configUpdate.insertionVerifier = vm.parseAddress(
            vm.readFile(
                string(
                    abi.encodePacked("./deployments/", vm.envString("CHAIN_NAME"), "/CurvyInsertionVerifier.address")
                )
            )
        );
        _configUpdate.aggregationVerifier = vm.parseAddress(
            vm.readFile(
                string(
                    abi.encodePacked("./deployments/", vm.envString("CHAIN_NAME"), "/CurvyAggregationVerifier.address")
                )
            )
        );
        _configUpdate.withdrawVerifier = vm.parseAddress(
            vm.readFile(
                string(abi.encodePacked("./deployments/", vm.envString("CHAIN_NAME"), "/CurvyWithdrawVerifier.address"))
            )
        );
        _configUpdate.operator = vm.envAddress("OPERATOR_ADDR");
        _configUpdate.csuc = vm.parseAddress(
            vm.readFile(string(abi.encodePacked("./deployments/", vm.envString("CHAIN_NAME"), "/CSUC.address")))
        );

        return _configUpdate;
    }

    uint256 private deployerPk;
    uint256 private operatorPk;
    address private operator;
    address private feeCollector;

    CurvyAggregator public aggregator;
}
