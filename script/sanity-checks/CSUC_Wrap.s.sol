// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {CSUC, CSUC_Types, CSUC_Constants, IERC20} from "../../src/csuc/CSUC.sol";

contract CSUC_Wrap_Script is Script {
    function run() public virtual {
        operatorPk = vm.envUint("OPERATOR_PK");
        csaPk = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender)));
        csa = vm.addr(csaPk);

        csuc = CSUC(
            vm.parseAddress(
                vm.readFile(string(abi.encodePacked("./deployments/", vm.envString("CHAIN_NAME"), "/CSUC.address")))
            )
        );

        vm.startBroadcast(operatorPk);

        payable(csa).transfer(0.0005 ether);

        IERC20(ERC20_Chainlink).approve(address(csuc), type(uint256).max);

        csuc.wrapERC20(csa, ERC20_Chainlink, 1_000_000);

        require(csuc.balanceOf(csa, ERC20_Chainlink) == 1_000_000, "Wrap:ERC20 failed!!!");

        vm.stopBroadcast();

        vm.startBroadcast(csaPk);

        uint256 _amount = 0.00001 ether;
        csuc.wrapNative{value: _amount}(csa);

        require(csuc.balanceOf(csa, CSUC_Constants.NATIVE_TOKEN) == _amount, "Wrap:Native failed!!!");

        vm.stopBroadcast();
    }

    uint256 public operatorPk;
    address public csa;
    uint256 public csaPk;

    address public ERC20_Chainlink = address(0x779877A7B0D9E8603169DdbD7836e478b4624789);

    CSUC public csuc;
    CSUC_Types.ActionHandlingInfoUpdate[] actionHandlingInfoUpdate;
}
