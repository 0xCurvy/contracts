// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";

import {MockERC20} from "../test/csuc/mocks/MockERC20.sol";

contract MockERC20_Deploy_Script is Script {
    function run() public {
        deployerPk = vm.envUint("DEPLOYER_PK");
        feeCollector = operator = vm.envAddress("OPERATOR_ADDR");

        vm.startBroadcast(deployerPk);

        uint256 _totalSupply = 1_000_000_000 * 10 ** 18;

        mockERC20 = new MockERC20(_totalSupply);
        console2.log("MockERC20 deployed at: ", address(mockERC20));

        string memory outputFile =
            string(abi.encodePacked("./deployments/", vm.envString("CHAIN_NAME"), "/MockERC20.address"));
        vm.writeFile(outputFile, vm.toString(address(mockERC20)));

        uint256 _individualAmount = _totalSupply / 100;

        // Curvy Users with non-zero ETH balance and zero ERC20 balance
        payable(vm.envAddress("USER_1_CSA_1_ADDR")).transfer(0.33 ether);
        payable(vm.envAddress("USER_2_CSA_1_ADDR")).transfer(0.33 ether);
        payable(vm.envAddress("USER_3_CSA_1_ADDR")).transfer(0.33 ether);

        // Curvy Users with zero ETH balance, and non-zero ERC20 balance
        mockERC20.dbg_mint(vm.envAddress("USER_1_CSA_2_ADDR"), _individualAmount);
        mockERC20.dbg_mint(vm.envAddress("USER_2_CSA_2_ADDR"), _individualAmount);
        mockERC20.dbg_mint(vm.envAddress("USER_3_CSA_2_ADDR"), _individualAmount);

        // Curvy Users with non-zero ETH balance, and non-zero ERC20 balance
        mockERC20.dbg_mint(vm.envAddress("USER_1_CSA_3_ADDR"), _individualAmount);
        mockERC20.dbg_mint(vm.envAddress("USER_2_CSA_3_ADDR"), _individualAmount);
        mockERC20.dbg_mint(vm.envAddress("USER_3_CSA_3_ADDR"), _individualAmount);

        vm.stopBroadcast();
    }

    uint256 private deployerPk;
    address private operator;
    address private feeCollector;

    MockERC20 public mockERC20;
}
