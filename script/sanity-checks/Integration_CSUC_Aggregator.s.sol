// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {CSUC, CSUC_Types, CSUC_Constants} from "../../src/csuc/CSUC.sol";
import {
    ICSUC_ActionHandler,
    CurvyAggregator_CSUC_ActionHandler,
    CurvyAggregator_Constants,
    CurvyAggregator_Types
} from "../../src/aggregator/csuc_action_handler/CurvyAggregator_CSUC_ActionHandler.sol";
import {CSUC_Wrap_Script} from "./CSUC_Wrap.s.sol";

contract Integration_CSUC_Aggregator_Script is Script, CSUC_Wrap_Script {
    function run() public override {
        CSUC_Wrap_Script.run();

        actionHandler = CurvyAggregator_CSUC_ActionHandler(
            vm.parseAddress(
                vm.readFile(
                    string(
                        abi.encodePacked(
                            "./deployments/", vm.envString("CHAIN_NAME"), "/CurvyAggregator_CSUC_ActionHandler.address"
                        )
                    )
                )
            )
        );

        vm.startBroadcast(operatorPk);

        uint256 _actionId = actionHandler.getActionId();

        address[] memory _tokens = new address[](2);
        _tokens[0] = CurvyAggregator_Constants.NATIVE_TOKEN;
        _tokens[1] = ERC20_Chainlink;

        uint256 _ownerHash = uint256(keccak256(abi.encodePacked(vm.randomAddress())));
        uint256 _amount = 1_000;

        for (uint256 i = 0; i < _tokens.length; ++i) {
            uint256 _tokenAsUint256 = uint256(uint160(_tokens[i]));

            uint256 _totalFee = csuc.getMandatoryFee(_actionId, _amount);

            CurvyAggregator_Types.Note[] memory _notes = new CurvyAggregator_Types.Note[](1);
            _notes[0] = CurvyAggregator_Types.Note({ownerHash: _ownerHash, token: _tokenAsUint256, amount: _amount});
            bytes memory _parameters = abi.encode(_notes);

            CSUC_Types.ActionPayload memory _payload = CSUC_Types.ActionPayload({
                actionId: _actionId,
                token: _tokens[i],
                amount: _amount,
                parameters: _parameters,
                totalFee: _totalFee,
                limit: block.number + 10
            });

            bytes32 _hash = csuc._hashActionPayload(csa, _payload);

            (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(csaPk, _hash);

            CSUC_Types.Action[] memory _actions = new CSUC_Types.Action[](1);
            _actions[0] =
                CSUC_Types.Action({from: csa, payload: _payload, signature_v: _v, signature_r: _r, signature_s: _s});
            uint256 _actionExecuted = csuc.operatorExecute(_actions);

            string memory _error = i == 0
                ? "Integration_CSUC_Aggregator_Script: wrapNative failed"
                : "Integration_CSUC_Aggregator_Script: wrapERC20 failed";

            require(_actionExecuted == 1, _error);
        }

        vm.stopBroadcast();
    }

    CurvyAggregator_CSUC_ActionHandler public actionHandler;
}
