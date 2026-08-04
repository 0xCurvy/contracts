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
} from "../../../src/v2/aggregator-alpha/CurvyAggregatorAlphaV2.sol";
import {
    CurvyAggregationVerifier
} from "../../../src/v2/aggregator-alpha/verifiers/CurvyAggregationVerifier.sol";
import {
    ICurvyAggregatorAlpha
} from "../../../src/v2/aggregator-alpha/ICurvyAggregatorAlpha.sol";
import {CurvyVaultV2} from "../../../src/v2/vault/CurvyVaultV2.sol";
import {CurvyTypes} from "../../../src/v2/utils/Types.sol";
import {
    AGG_MAX_INPUTS,
    AGG_MAX_OUTPUTS,
    AGG_TREE_DEPTH,
    AggregationFixtures
} from "./fixtures/aggregation.fixtures.sol";

contract AggregationTest is Test {
    using stdStorage for StdStorage;

    CurvyAggregatorAlphaV2 public curvyAggregatorAlphaV2;
    CurvyVaultV2 public vault;
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

        // Vault holds the per-token gas-cost table and pushes the root to the aggregator.
        CurvyVaultV2 vaultImpl = new CurvyVaultV2();
        vault = CurvyVaultV2(
            address(
                new ERC1967Proxy(address(vaultImpl), abi.encodeCall(CurvyVaultV2.initialize, (address(this))))
            )
        );
        vault.setCurvyAggregatorAddress(address(curvyAggregatorAlphaV2));

        AggregationFixtures.Input memory fixture = AggregationFixtures.input();

        curvyAggregatorAlphaV2.updateConfig(
            CurvyTypes.AggregatorConfigurationUpdate({curvyVault: address(vault), portalFactory: address(0)})
        );
        curvyAggregatorAlphaV2.setAggregationVerifier(
            AGG_MAX_INPUTS,
            AGG_MAX_OUTPUTS,
            address(verifier)
        );
        curvyAggregatorAlphaV2.setProtocolFees(fixture.protocolFeePerThousand);
        // Per-token commitment gas cost: publish one entry per REGISTERED token (ids ascending
        // from 1) + the committed root, via the vault. The gas-fee tree keeps a fixed
        // 2^GAS_TREE_DEPTH leaves, but only the registered prefix is ever written — the rest stay
        // a zero buffer — so the full padded table is never passed. The vault pushes the root to
        // the aggregator (onlyCurvyVault). `initialize` reserves tokenId 1, which is the only one
        // this fixture uses; `commitmentGasCosts` is indexed by tokenId (index 0 unused).
        CurvyTypes.GasFees[] memory gasFees = new CurvyTypes.GasFees[](1);
        gasFees[0] = CurvyTypes.GasFees({
            tokenId: fixture.tokenId,
            portalDeployment: 0,
            pendingNoteCommitment: fixture.commitmentGasCosts[fixture.tokenId],
            withdrawal: 0
        });
        vault.setPerTokenGasFees(gasFees, fixture.commitPendingNotesGasFeeRoot);
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
            curvyAggregatorAlphaV2.getAggregationVerifier(AGG_MAX_INPUTS, AGG_MAX_OUTPUTS),
            address(verifier)
        );
        assertEq(
            curvyAggregatorAlphaV2.protocolFeePerThousand(),
            fixture.protocolFeePerThousand
        );
        assertTrue(curvyAggregatorAlphaV2.validNotesRoot(fixture.notesRoot));
        assertEq(
            curvyAggregatorAlphaV2.commitmentFeeRoot(),
            fixture.commitPendingNotesGasFeeRoot,
            "commitment fee root pushed via vault"
        );
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
                curvyAggregatorAlphaV2.nullifiers(
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
            AGG_MAX_OUTPUTS,
            fixture.proof_a,
            fixture.proof_b,
            fixture.proof_c,
            fixture.public_signals
        );

        // Post: nullifiers registered, output notes PENDING, batch index advanced
        for (uint256 i = 0; i < AGG_MAX_INPUTS; i++) {
            if (fixture.inputNullifiers[i] == 0) continue;
            assertTrue(
                curvyAggregatorAlphaV2.nullifiers(
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
