// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";
import {console} from "forge-std/console.sol";
import {
    ERC1967Proxy
} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {
    CurvyAggregatorAlphaV2
} from "../../../contracts/aggregator-beta/CurvyAggregatorAlphaV2.sol";
import {
    CurvyPendingNotesCommitmentVerifier
} from "../../../contracts/aggregator-beta/verifiers/CurvyPendingNotesCommitmentVerifier.sol";
import {
    BATCH_SIZE,
    TREE_DEPTH,
    PendingNotesCommitmentFixtures
} from "./fixtures/pendingNotesCommitment.fixtures.sol";
import {
    ICurvyAggregatorAlpha
} from "../../../contracts/aggregator-beta/ICurvyAggregatorAlpha.sol";

contract PendingNotesCommitmentTest is Test {
    using stdStorage for StdStorage;

    CurvyAggregatorAlphaV2 public curvyAggregatorAlphaV2;
    CurvyPendingNotesCommitmentVerifier
        public curvyPendingNotesCommitmentVerifier;

    function setUp() public {
        CurvyAggregatorAlphaV2 implementation = new CurvyAggregatorAlphaV2();
        bytes memory initData = abi.encodeCall(
            CurvyAggregatorAlphaV2.initialize,
            (address(this))
        );
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        curvyAggregatorAlphaV2 = CurvyAggregatorAlphaV2(address(proxy));

        curvyPendingNotesCommitmentVerifier = new CurvyPendingNotesCommitmentVerifier();

        curvyAggregatorAlphaV2.setPendingNotesCommitmentVerifier(
            BATCH_SIZE,
            TREE_DEPTH,
            address(curvyPendingNotesCommitmentVerifier)
        );

        PendingNotesCommitmentFixtures.Input
            memory fixture = PendingNotesCommitmentFixtures.input();

        assertEq(
            curvyAggregatorAlphaV2.getPendingNotesCommitmentVerifier(
                BATCH_SIZE,
                TREE_DEPTH
            ),
            address(curvyPendingNotesCommitmentVerifier)
        );
        assertEq(
            curvyAggregatorAlphaV2.getCurrentNotesTreeRoot(),
            fixture.currentNotesRoot
        );
        assertEq(curvyAggregatorAlphaV2.getCurrentNotesBatchIndex(), 0);
        assertEq(
            curvyAggregatorAlphaV2.getCurrentNoteIndex(),
            fixture.currentNoteIndex
        );
    }

    function test_commitPendingNotes() public {
        console.log(
            "> Testing commitment of two pending notes and three dummy notes"
        );
        PendingNotesCommitmentFixtures.Input
            memory fixture = PendingNotesCommitmentFixtures.input();

        uint256[] memory noteIds = new uint256[](BATCH_SIZE);
        for (uint256 i = 0; i < BATCH_SIZE; i++) {
            assertEq(
                uint256(curvyAggregatorAlphaV2.noteStatus(fixture.noteIds[i])),
                uint256(ICurvyAggregatorAlpha.NoteStatus.UNKNOWN)
            );
            noteIds[i] = fixture.noteIds[i];
        }

        _setNotePending(fixture.noteIds[0]);
        _setNotePending(fixture.noteIds[1]);

        assertTrue(
            curvyPendingNotesCommitmentVerifier.verifyProof(
                fixture.proof_a,
                fixture.proof_b,
                fixture.proof_c,
                fixture.public_signals
            ),
            "fixture proof should verify against mod-reduced public signal"
        );

        curvyAggregatorAlphaV2.commitPendingNotes(
            BATCH_SIZE,
            TREE_DEPTH,
            noteIds,
            fixture.newNotesRoot,
            fixture.proof_a,
            fixture.proof_b,
            fixture.proof_c
        );

        assertEq(
            curvyAggregatorAlphaV2.getCurrentNotesTreeRoot(),
            fixture.newNotesRoot
        );
        assertEq(
            curvyAggregatorAlphaV2.getCurrentNoteIndex(),
            fixture.newNoteIndex
        );
        assertEq(curvyAggregatorAlphaV2.getCurrentNotesBatchIndex(), 1);
        assertEq(
            uint256(curvyAggregatorAlphaV2.noteStatus(fixture.noteIds[0])),
            uint256(ICurvyAggregatorAlpha.NoteStatus.INCLUDED)
        );
        assertEq(
            uint256(curvyAggregatorAlphaV2.noteStatus(fixture.noteIds[1])),
            uint256(ICurvyAggregatorAlpha.NoteStatus.INCLUDED)
        );
        assertTrue(curvyAggregatorAlphaV2.validNotesRoot(fixture.newNotesRoot));
    }

    function _setNotePending(uint256 noteId) internal {
        stdstore
            .target(address(curvyAggregatorAlphaV2))
            .sig("noteStatus(uint256)")
            .with_key(noteId)
            .checked_write(uint256(ICurvyAggregatorAlpha.NoteStatus.PENDING));
    }
}
