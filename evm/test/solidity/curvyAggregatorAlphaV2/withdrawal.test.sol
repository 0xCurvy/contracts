// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";
import { StdStorage, stdStorage } from "forge-std/StdStorage.sol";
import { console } from "forge-std/console.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { CurvyAggregatorAlphaV2 } from "../../../src/v2/aggregator-alpha/CurvyAggregatorAlphaV2.sol";
import { CurvyVaultV2 } from "../../../src/v2/vault/CurvyVaultV2.sol";
import { CurvyWithdrawalVerifier } from "../../../src/v2/aggregator-alpha/verifiers/CurvyWithdrawalVerifier.sol";
import { CurvyTypes } from "../../../src/v2/utils/Types.sol";
import {
    WDR_MAX_INPUTS,
    WDR_TREE_DEPTH,
    WithdrawalFixtures
} from "./fixtures/withdrawal.fixtures.sol";

contract WithdrawalTest is Test {
    using stdStorage for StdStorage;

    CurvyAggregatorAlphaV2 public aggregator;
    CurvyVaultV2 public vault;
    CurvyWithdrawalVerifier public verifier;

    function setUp() public {
        // Aggregator proxy
        CurvyAggregatorAlphaV2 aggImpl = new CurvyAggregatorAlphaV2();
        bytes memory aggInit = abi.encodeCall(CurvyAggregatorAlphaV2.initialize, (address(this)));
        aggregator = CurvyAggregatorAlphaV2(address(new ERC1967Proxy(address(aggImpl), aggInit)));

        // Vault proxy (V2)
        CurvyVaultV2 vaultImpl = new CurvyVaultV2();
        bytes memory vaultInit = abi.encodeCall(CurvyVaultV2.initialize, (address(this)));
        vault = CurvyVaultV2(address(new ERC1967Proxy(address(vaultImpl), vaultInit)));

        // Wire vault <-> aggregator
        vault.setCurvyAggregatorAddress(address(aggregator));
        // Disable the proportional vault fees to keep accounting clean (gas fee is separate).
        vault.setFeeAmount(CurvyTypes.FeeUpdate({ depositFee: 0, withdrawalFee: 0 }));

        aggregator.updateConfig(
            CurvyTypes.AggregatorConfigurationUpdate({
                curvyVault: address(vault),
                portalFactory: address(0)
            })
        );

        // Withdrawal verifier + zero protocol fee
        verifier = new CurvyWithdrawalVerifier();
        aggregator.setWithdrawalVerifier(WDR_MAX_INPUTS, address(verifier));
        aggregator.setProtocolFees(0);

        WithdrawalFixtures.Input memory fixture = WithdrawalFixtures.input();

        // Seed validNotesRoot
        stdstore
            .target(address(aggregator))
            .sig("validNotesRoot(uint256)")
            .with_key(fixture.notesRoot)
            .checked_write(true);

        // Fund vault for tokenId=1 (ETH): set aggregator's internal balance + give vault real ETH
        stdstore
            .target(address(vault))
            .sig("balanceOf(address,uint256)")
            .with_key(address(aggregator))
            .with_key(fixture.tokenId)
            .checked_write(fixture.withdrawnAmount);
        vm.deal(address(vault), fixture.withdrawnAmount);

        // Sanity
        assertEq(
            aggregator.getWithdrawalVerifier(WDR_MAX_INPUTS),
            address(verifier)
        );
        assertEq(vault.balanceOf(address(aggregator), fixture.tokenId), fixture.withdrawnAmount);
        assertEq(address(vault).balance, fixture.withdrawnAmount);
        assertTrue(aggregator.validNotesRoot(fixture.notesRoot));
    }

    function test_submitWithdrawalRequest() public {
        console.log("> Testing submitWithdrawalRequest withdraws 1500 wei (no gas fee) to destination");
        WithdrawalFixtures.Input memory fixture = WithdrawalFixtures.input();

        // Verify proof directly against verifier
        uint256[6] memory pub;
        for (uint256 i = 0; i < 6; i++) pub[i] = fixture.public_signals[i];
        assertTrue(
            verifier.verifyProof(fixture.proof_a, fixture.proof_b, fixture.proof_c, pub),
            "fixture proof should verify against withdrawal verifier"
        );

        // Pre-state
        for (uint256 i = 0; i < WDR_MAX_INPUTS; i++) {
            if (fixture.inputNullifiers[i] == 0) continue;
            assertFalse(aggregator.nullifiers(fixture.inputNullifiers[i]));
        }
        uint256 prevDestBalance = fixture.destinationAddress.balance;
        uint256 prevVaultBalance = address(vault).balance;
        uint256 prevAggInternalBalance = vault.balanceOf(address(aggregator), fixture.tokenId);
        uint256 prevNullifierBatchIndex = aggregator.getCurrentNullifiersBatchIndex();

        // Submit
        aggregator.submitWithdrawalRequest(
            WDR_MAX_INPUTS,
            fixture.proof_a,
            fixture.proof_b,
            fixture.proof_c,
            fixture.public_signals
        );

        // No gas fee set → full amount to destination
        uint256 netAmount = fixture.withdrawnAmount;

        assertEq(
            fixture.destinationAddress.balance,
            prevDestBalance + netAmount,
            "destination should receive net withdrawn amount"
        );
        assertEq(
            address(vault).balance,
            prevVaultBalance - netAmount,
            "vault ETH balance should decrease by net amount"
        );
        assertEq(
            vault.balanceOf(address(aggregator), fixture.tokenId),
            prevAggInternalBalance - netAmount,
            "aggregator internal vault balance should be debited"
        );

        // Nullifiers registered
        for (uint256 i = 0; i < WDR_MAX_INPUTS; i++) {
            if (fixture.inputNullifiers[i] == 0) continue;
            assertTrue(aggregator.nullifiers(fixture.inputNullifiers[i]));
        }
        assertEq(aggregator.getCurrentNullifiersBatchIndex(), prevNullifierBatchIndex + 1);
    }

    function test_submitWithdrawalRequest_withGasFee() public {
        console.log("> Testing submitWithdrawalRequest: gas reimbursement goes to relayer (msg.sender) EOA");
        WithdrawalFixtures.Input memory fixture = WithdrawalFixtures.input();

        uint256 gasFee = 100;
        // Per-token withdrawal gas cost lives on the vault (tokenId is public on withdrawals), and
        // is published together with the deployment/commitment costs in one `GasFees` entry. The
        // commitment root is irrelevant here — only the aggregation path checks it — but it must be
        // non-zero, so pass a placeholder.
        CurvyTypes.GasFees[] memory gasFees = new CurvyTypes.GasFees[](1);
        gasFees[0] = CurvyTypes.GasFees({
            tokenId: fixture.tokenId,
            portalDeployment: 0,
            pendingNoteCommitment: 0,
            withdrawal: gasFee
        });
        vault.setPerTokenGasFees(gasFees, 1);

        // Relayer = address(this) (msg.sender of submitWithdrawalRequest)
        uint256 prevRelayerBalance = address(this).balance;
        uint256 prevDestBalance = fixture.destinationAddress.balance;

        aggregator.submitWithdrawalRequest(
            WDR_MAX_INPUTS,
            fixture.proof_a,
            fixture.proof_b,
            fixture.proof_c,
            fixture.public_signals
        );

        uint256 netAmount = fixture.withdrawnAmount - gasFee; // protocolFee = 0
        assertEq(
            fixture.destinationAddress.balance,
            prevDestBalance + netAmount,
            "destination should receive net amount after gas fee"
        );
        assertEq(
            address(this).balance,
            prevRelayerBalance + gasFee,
            "relayer (msg.sender) should receive the gas reimbursement"
        );
    }

    receive() external payable {}
}
