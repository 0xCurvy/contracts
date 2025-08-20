// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {CurvyEntrypoint} from "../../src/csuc/experiments/CurvyEntrypoint.sol";

contract CurvyEntrypoint_Deploy_Script is Script {
    function run() public {
        deployerPk = vm.envUint("DEPLOYER_PK");

        vm.startBroadcast(deployerPk);

        ce = new CurvyEntrypoint{salt: keccak256(abi.encode(1301))}(
            address(0xE38316a35cfe43f36779Ee83784FA5d26464f0Ec), address(0xE38316a35cfe43f36779Ee83784FA5d26464f0Ec)
        );
        console2.log("CurvyEntrypoint deployed at: ", address(ce));

        // ce.enterCSUC(address(0xE38316a35cfe43f36779Ee83784FA5d26464f0Ec));

        vm.stopBroadcast();
    }

    uint256 private deployerPk;

    CurvyEntrypoint public ce;
}
