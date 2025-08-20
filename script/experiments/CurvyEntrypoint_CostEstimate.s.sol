// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {CurvyEntrypoint} from "../../src/csuc/experiments/CurvyEntrypoint.sol";
import {CurvyEntrypointManager} from "../../src/csuc/experiments/CurvyEntrypointManager.sol";

contract CurvyEntrypoint_CostEstimate_Script is Script {
    function run() public {
        deployerPk = vm.envUint("DEPLOYER_PK");

        vm.startBroadcast(deployerPk);

        cem = new CurvyEntrypointManager{salt: keccak256(abi.encode(1303))}();

        CurvyEntrypoint[] memory ces = new CurvyEntrypoint[](4);
        CurvyEntrypointManager.CSUC_Target[] memory _targets = new CurvyEntrypointManager.CSUC_Target[](4);
        for (uint256 i = 0; i < ces.length; i++) {
            ces[i] = new CurvyEntrypoint{salt: keccak256(abi.encode(1301 + i))}(
                address(0xE38316a35cfe43f36779Ee83784FA5d26464f0Ec), address(0xE38316a35cfe43f36779Ee83784FA5d26464f0Ec)
            );
            console2.log("CurvyEntrypoint deployed at: ", address(ces[i]));
            _targets[i].target = address(ces[i]);
            _targets[i].token = new address[](1);
            _targets[i].token[0] = ERC20_TOKEN;

            IERC20(ERC20_TOKEN).transfer(address(ces[i]), 13 + i);
        }

        cem.enterCSUC(_targets);

        // ce.enterCSUC(address(0xE38316a35cfe43f36779Ee83784FA5d26464f0Ec));

        vm.stopBroadcast();
    }

    address public constant ERC20_TOKEN = address(0x779877A7B0D9E8603169DdbD7836e478b4624789); // Replace with actual ERC20 token address

    uint256 private deployerPk;

    CurvyEntrypoint public ce;
    CurvyEntrypointManager public cem;
}
