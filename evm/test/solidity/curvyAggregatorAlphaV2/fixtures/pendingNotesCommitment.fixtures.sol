// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { Vm } from "forge-std/Vm.sol";
import { stdJson } from "forge-std/StdJson.sol";

uint256 constant BATCH_SIZE = 5;
uint256 constant TREE_DEPTH = 30;

string constant PENDING_NOTES_FIXTURE_PATH =
    "test/solidity/curvyAggregatorAlphaV2/fixtures/pendingNotesCommitment.fixtures.json";

library PendingNotesCommitmentFixtures {
    using stdJson for string;

    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    struct Input {
        uint256[BATCH_SIZE] noteIds;
        uint256 currentNotesRoot;
        uint256 newNotesRoot;
        uint256 currentNoteIndex;
        uint256 newNoteIndex;
        uint256[2] proof_a;
        uint256[2][2] proof_b;
        uint256[2] proof_c;
        uint256[1] public_signals;
    }

    function input() internal view returns (Input memory i) {
        string memory j = vm.readFile(PENDING_NOTES_FIXTURE_PATH);

        uint256[] memory noteIds = vm.parseJsonUintArray(j, ".noteIds");
        require(noteIds.length == BATCH_SIZE, "PendingNotesFixture: noteIds length mismatch");
        for (uint256 k = 0; k < BATCH_SIZE; k++) {
            i.noteIds[k] = noteIds[k];
        }

        i.currentNotesRoot = vm.parseJsonUint(j, ".currentNotesRoot");
        i.newNotesRoot = vm.parseJsonUint(j, ".newNotesRoot");
        i.currentNoteIndex = vm.parseJsonUint(j, ".currentNoteIndex");
        i.newNoteIndex = vm.parseJsonUint(j, ".newNoteIndex");

        uint256[] memory a = vm.parseJsonUintArray(j, ".proof.a");
        i.proof_a = [a[0], a[1]];

        uint256[] memory b0 = vm.parseJsonUintArray(j, ".proof.b[0]");
        uint256[] memory b1 = vm.parseJsonUintArray(j, ".proof.b[1]");
        i.proof_b = [[b0[0], b0[1]], [b1[0], b1[1]]];

        uint256[] memory c = vm.parseJsonUintArray(j, ".proof.c");
        i.proof_c = [c[0], c[1]];

        uint256[] memory signals = vm.parseJsonUintArray(j, ".publicSignals");
        require(signals.length == 1, "PendingNotesFixture: signals length mismatch");
        i.public_signals = [signals[0]];
    }
}
