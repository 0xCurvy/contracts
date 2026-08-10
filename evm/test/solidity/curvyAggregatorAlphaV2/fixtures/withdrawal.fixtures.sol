// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { Vm } from "forge-std/Vm.sol";

uint256 constant WDR_MAX_INPUTS = 2;
uint256 constant WDR_TREE_DEPTH = 30;
uint256 constant WDR_PUBLIC_SIGNALS_LEN = 6;

string constant WITHDRAWAL_FIXTURE_PATH =
    "test/solidity/curvyAggregatorAlphaV2/fixtures/withdrawal.fixtures.json";

library WithdrawalFixtures {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    struct Input {
        uint256 tokenId;
        address destinationAddress;
        uint256 withdrawnAmount;
        uint256 notesRoot;
        uint256[WDR_MAX_INPUTS] inputNullifiers;
        uint256[2] proof_a;
        uint256[2][2] proof_b;
        uint256[2] proof_c;
        uint256[] public_signals;
    }

    function input() internal view returns (Input memory i) {
        string memory j = vm.readFile(WITHDRAWAL_FIXTURE_PATH);

        i.tokenId = vm.parseJsonUint(j, ".tokenId");
        i.destinationAddress = vm.parseJsonAddress(j, ".destinationAddress");
        i.withdrawnAmount = vm.parseJsonUint(j, ".withdrawnAmount");
        i.notesRoot = vm.parseJsonUint(j, ".notesRoot");

        uint256[] memory nfs = vm.parseJsonUintArray(j, ".inputNullifiers");
        require(nfs.length == WDR_MAX_INPUTS, "WithdrawalFixture: nullifiers length");
        for (uint256 k = 0; k < WDR_MAX_INPUTS; k++) i.inputNullifiers[k] = nfs[k];

        uint256[] memory a = vm.parseJsonUintArray(j, ".proof.a");
        i.proof_a = [a[0], a[1]];

        uint256[] memory b0 = vm.parseJsonUintArray(j, ".proof.b[0]");
        uint256[] memory b1 = vm.parseJsonUintArray(j, ".proof.b[1]");
        i.proof_b = [[b0[0], b0[1]], [b1[0], b1[1]]];

        uint256[] memory c = vm.parseJsonUintArray(j, ".proof.c");
        i.proof_c = [c[0], c[1]];

        i.public_signals = vm.parseJsonUintArray(j, ".publicSignals");
        require(i.public_signals.length == WDR_PUBLIC_SIGNALS_LEN, "WithdrawalFixture: signals length");
    }
}
