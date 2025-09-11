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

        string memory usersJson = vm.readFile("../devenv/users.json");
        address[][] memory users = abi.decode(
            vm.parseJson(usersJson, "."),
            (address[][])
        );

        for (uint256 i = 0; i < users.length; i++) {
            payable(users[i][0]).transfer(0.33 ether);
            mockERC20.dbg_mint(users[i][1], _individualAmount);
            payable(users[i][2]).transfer(0.13 ether);
        }

        vm.stopBroadcast();
    }

    uint256 private deployerPk;
    address private operator;
    address private feeCollector;

    MockERC20 public mockERC20;
}
