// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {CSUC, CSUC_Types, CSUC_Constants} from "../../src/csuc/CSUC.sol";
import {CSUC_Wrap_Script} from "./CSUC_Wrap.s.sol";

contract CSUC_Transfer_Script is CSUC_Wrap_Script {
    function run() public override {
        CSUC_Wrap_Script.run();

        uint256 _nTransfers = 3;
        CSUC_Types.Action[] memory _actions = new CSUC_Types.Action[](_nTransfers);
        for (uint256 i = 0; i < _nTransfers; i++) {
            uint256 _amount = csuc.balanceOf(csa, CSUC_Constants.NATIVE_TOKEN) / 17;
            uint256 _totalFee = csuc.getMandatoryFee(CSUC_Constants.TRANSFER_ACTION_ID, _amount);

            CSUC_Types.ActionPayload memory _payload = CSUC_Types.ActionPayload({
                actionId: CSUC_Constants.TRANSFER_ACTION_ID,
                token: CSUC_Constants.NATIVE_TOKEN,
                amount: _amount,
                parameters: abi.encode(vm.randomAddress()),
                totalFee: _totalFee,
                limit: block.number + 10
            });

            uint256 _nonce = _nTransfers;
            bytes32 _hash = csuc._hashActionPayloadWithCustomNonce(_payload, _nonce);

            (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(csaPk, _hash);

            _actions[i] =
                CSUC_Types.Action({from: csa, payload: _payload, signature_v: _v, signature_r: _r, signature_s: _s});
        }

        vm.startBroadcast(operatorPk);

        uint256 _actionsExecuted = csuc.operatorExecute(_actions);
        // TODO: debug
        // vm.assertEq(_actionsExecuted, _nTransfers, "Expected all actions to be executed");

        vm.stopBroadcast();
    }
}
