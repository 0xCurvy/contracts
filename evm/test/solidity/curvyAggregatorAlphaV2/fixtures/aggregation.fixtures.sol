// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { Vm } from "forge-std/Vm.sol";

uint256 constant AGG_MAX_INPUTS = 2;
uint256 constant AGG_MAX_OUTPUTS = 3;
uint256 constant AGG_TREE_DEPTH = 30;
uint256 constant AGG_PUBLIC_SIGNALS_LEN = 30;

string constant AGGREGATION_FIXTURE_PATH =
    "test/solidity/curvyAggregatorAlphaV2/fixtures/aggregation.fixtures.json";

library AggregationFixtures {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    struct Input {
        uint256 protocolFeePerThousand;
        uint256 gasFee;
        uint256[2] feeNotePublicKey;
        uint256 notesRoot;
        uint256[AGG_MAX_INPUTS] inputNoteIds;
        uint256[AGG_MAX_INPUTS] inputNullifiers;
        uint256[AGG_MAX_OUTPUTS] outputNoteIds;
        uint256[2] proof_a;
        uint256[2][2] proof_b;
        uint256[2] proof_c;
        uint256[] public_signals;
    }

    function input() internal view returns (Input memory i) {
        string memory j = vm.readFile(AGGREGATION_FIXTURE_PATH);

        i.protocolFeePerThousand = vm.parseJsonUint(j, ".protocolFeePerThousand");
        i.gasFee = vm.parseJsonUint(j, ".gasFee");

        uint256[] memory feePk = vm.parseJsonUintArray(j, ".feeNotePublicKey");
        i.feeNotePublicKey = [feePk[0], feePk[1]];

        i.notesRoot = vm.parseJsonUint(j, ".notesRoot");

        uint256[] memory inIds = vm.parseJsonUintArray(j, ".inputNoteIds");
        require(inIds.length == AGG_MAX_INPUTS, "AggFixture: inputNoteIds length");
        for (uint256 k = 0; k < AGG_MAX_INPUTS; k++) i.inputNoteIds[k] = inIds[k];

        uint256[] memory inNfs = vm.parseJsonUintArray(j, ".inputNullifiers");
        require(inNfs.length == AGG_MAX_INPUTS, "AggFixture: inputNullifiers length");
        for (uint256 k = 0; k < AGG_MAX_INPUTS; k++) i.inputNullifiers[k] = inNfs[k];

        uint256[] memory outIds = vm.parseJsonUintArray(j, ".outputNoteIds");
        require(outIds.length == AGG_MAX_OUTPUTS, "AggFixture: outputNoteIds length");
        for (uint256 k = 0; k < AGG_MAX_OUTPUTS; k++) i.outputNoteIds[k] = outIds[k];

        uint256[] memory a = vm.parseJsonUintArray(j, ".proof.a");
        i.proof_a = [a[0], a[1]];

        uint256[] memory b0 = vm.parseJsonUintArray(j, ".proof.b[0]");
        uint256[] memory b1 = vm.parseJsonUintArray(j, ".proof.b[1]");
        i.proof_b = [[b0[0], b0[1]], [b1[0], b1[1]]];

        uint256[] memory c = vm.parseJsonUintArray(j, ".proof.c");
        i.proof_c = [c[0], c[1]];

        i.public_signals = vm.parseJsonUintArray(j, ".publicSignals");
        require(i.public_signals.length == AGG_PUBLIC_SIGNALS_LEN, "AggFixture: signals length");
    }
}
