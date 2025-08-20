// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {CurvyEntrypoint_UsingConstants} from "../../src/csuc/experiments/CurvyEntrypoint_UsingConstants.sol";

contract CurvyEntrypoint_UsingConstants_Deploy_Script is Script {
    function run() public {
        deployerPk = vm.envUint("DEPLOYER_PK");

        vm.startBroadcast(deployerPk);

        // ce = new CurvyEntrypoint_UsingConstants{salt: keccak256(abi.encode(1302))}();
        // console2.log("CurvyEntrypoint_UsingConstants deployed at: ", address(ce));
        ce2 = CurvyEntrypoint_UsingConstants(0xd9B890b379f55c5394c0B600B9F0E4313dD51DA3);
        ce2.enterCSUC(address(0x779877A7B0D9E8603169DdbD7836e478b4624789));
        // ce.enterCSUC(address(0xE38316a35cfe43f36779Ee83784FA5d26464f0Ec));

        vm.stopBroadcast();
    }

    uint256 private deployerPk;

    CurvyEntrypoint_UsingConstants public ce;
    CurvyEntrypoint_UsingConstants public ce2;
}
