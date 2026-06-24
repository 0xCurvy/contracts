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
    CurvyAggregationVerifier
} from "../../../contracts/aggregator-beta/verifiers/CurvyAggregationVerifier.sol";
import {
    ICurvyAggregatorAlpha
} from "../../../contracts/aggregator-beta/ICurvyAggregatorAlpha.sol";
import {
    AGG_MAX_INPUTS,
    AGG_MAX_OUTPUTS,
    AGG_TREE_DEPTH,
    AggregationFixtures
} from "./fixtures/aggregation.fixtures.sol";

contract AggregationTest is Test {
    using stdStorage for StdStorage;

    CurvyAggregatorAlphaV2 public curvyAggregatorAlphaV2;
    CurvyAggregationVerifier public verifier;

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

        verifier = new CurvyAggregationVerifier();

        AggregationFixtures.Input memory fixture = AggregationFixtures.input();

        curvyAggregatorAlphaV2.setAggregationVerifier(
            AGG_MAX_INPUTS,
            AGG_MAX_OUTPUTS,
            AGG_TREE_DEPTH,
            address(verifier)
        );
        curvyAggregatorAlphaV2.setFees(
            fixture.protocolFeePerThousand,
            fixture.gasFee
        );
        curvyAggregatorAlphaV2.setFeeNotePublicKey(
            fixture.feeNotePublicKey[0],
            fixture.feeNotePublicKey[1]
        );

        // Seed referenced notes root as valid (would normally land via commitPendingNotes).
        stdstore
            .target(address(curvyAggregatorAlphaV2))
            .sig("validNotesRoot(uint256)")
            .with_key(fixture.notesRoot)
            .checked_write(true);

        assertEq(
            curvyAggregatorAlphaV2.getAggregationVerifier(
                AGG_MAX_INPUTS,
                AGG_MAX_OUTPUTS,
                AGG_TREE_DEPTH
            ),
            address(verifier)
        );
        assertEq(
            curvyAggregatorAlphaV2.protocolFeePerThousand(),
            fixture.protocolFeePerThousand
        );
        assertEq(curvyAggregatorAlphaV2.gasFee(), fixture.gasFee);
        assertTrue(curvyAggregatorAlphaV2.validNotesRoot(fixture.notesRoot));
    }

    function test_submitAggregationRequest() public {
        console.log(
            "> Testing submitAggregationRequest with 2 input notes, 3 output notes"
        );
        AggregationFixtures.Input memory fixture = AggregationFixtures.input();

        // Verify proof directly against verifier first
        uint256[31] memory pub;
        for (uint256 i = 0; i < 31; i++) pub[i] = fixture.public_signals[i];
        assertTrue(
            verifier.verifyProof(
                fixture.proof_a,
                fixture.proof_b,
                fixture.proof_c,
                pub
            ),
            "fixture proof should verify against aggregation verifier"
        );

        // Pre-checks: nullifiers unseen, output notes UNKNOWN
        for (uint256 i = 0; i < AGG_MAX_INPUTS; i++) {
            if (fixture.inputNullifiers[i] == 0) continue;
            assertFalse(
                curvyAggregatorAlphaV2.aggregationNullifiers(
                    fixture.inputNullifiers[i]
                )
            );
        }
        for (uint256 i = 0; i < AGG_MAX_OUTPUTS; i++) {
            if (fixture.outputNoteIds[i] == 0) continue;
            assertEq(
                uint256(
                    curvyAggregatorAlphaV2.noteStatus(fixture.outputNoteIds[i])
                ),
                uint256(ICurvyAggregatorAlpha.NoteStatus.UNKNOWN)
            );
        }

        uint256 prevNullifierBatchIndex = curvyAggregatorAlphaV2
            .getCurrentNullifiersBatchIndex();

        curvyAggregatorAlphaV2.submitAggregationRequest(
            AGG_MAX_INPUTS,
            fixture.proof_a,
            fixture.proof_b,
            fixture.proof_c,
            fixture.public_signals
        );

        // Post: nullifiers registered, output notes PENDING, batch index advanced
        for (uint256 i = 0; i < AGG_MAX_INPUTS; i++) {
            if (fixture.inputNullifiers[i] == 0) continue;
            assertTrue(
                curvyAggregatorAlphaV2.aggregationNullifiers(
                    fixture.inputNullifiers[i]
                )
            );
        }
        for (uint256 i = 0; i < AGG_MAX_OUTPUTS; i++) {
            if (fixture.outputNoteIds[i] == 0) continue;
            assertEq(
                uint256(
                    curvyAggregatorAlphaV2.noteStatus(fixture.outputNoteIds[i])
                ),
                uint256(ICurvyAggregatorAlpha.NoteStatus.PENDING)
            );
        }
        assertEq(
            curvyAggregatorAlphaV2.getCurrentNullifiersBatchIndex(),
            prevNullifierBatchIndex + 1
        );
    }
}
