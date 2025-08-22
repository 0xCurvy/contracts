// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";

import {Multicall3} from "../src/utils/Multicall3.sol";

contract Multicall3_Deploy_Script is Script {
    function run() public {
        deployerPk = vm.envUint("DEPLOYER_PK");
        feeCollector = operator = vm.envAddress("OPERATOR_ADDR");

        vm.startBroadcast(deployerPk);

        multicall3 = new Multicall3();
        console2.log("Multicall3 deployed at: ", address(multicall3));

        string memory outputFile =
            string(abi.encodePacked("./deployments/", vm.envString("CHAIN_NAME"), "/Multicall3.address"));
        vm.writeFile(outputFile, vm.toString(address(multicall3)));

        vm.stopBroadcast();
    }

    uint256 private deployerPk;
    address private operator;
    address private feeCollector;

    Multicall3 public multicall3;
}
