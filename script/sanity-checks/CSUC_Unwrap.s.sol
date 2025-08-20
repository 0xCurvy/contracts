// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {CSUC, CSUC_Types, CSUC_Constants} from "../../src/csuc/CSUC.sol";
import {CSUC_Wrap_Script} from "./CSUC_Wrap.s.sol";

contract CSUC_Unwrap_Script is Script, CSUC_Wrap_Script {
    function run() public override {
        CSUC_Wrap_Script.run();

        vm.startBroadcast(operatorPk);

        uint256 _amount = csuc.balanceOf(csa, CSUC_Constants.NATIVE_TOKEN);

        uint256 _totalFee = csuc.getMandatoryFee(CSUC_Constants.WITHDRAWAL_ACTION_ID, _amount);

        CSUC_Types.ActionPayload memory _payload = CSUC_Types.ActionPayload({
            actionId: CSUC_Constants.WITHDRAWAL_ACTION_ID,
            token: CSUC_Constants.NATIVE_TOKEN,
            amount: 1,
            parameters: abi.encode(vm.randomAddress()),
            totalFee: _totalFee,
            limit: block.number + 10
        });

        bytes32 _hash = csuc._hashActionPayload(csa, _payload);

        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(csaPk, _hash);

        CSUC_Types.Action memory _action =
            CSUC_Types.Action({from: csa, payload: _payload, signature_v: _v, signature_r: _r, signature_s: _s});

        csuc.unwrap(_action);

        vm.stopBroadcast();
    }
}
