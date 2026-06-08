// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";
import { StdStorage, stdStorage } from "forge-std/StdStorage.sol";
import { console } from "forge-std/console.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { CurvyAggregatorAlphaV2 } from "../../../contracts/aggregator-beta/CurvyAggregatorAlphaV2.sol";
import { CurvyVaultV1 } from "../../../contracts/vault/CurvyVaultV1.sol";
import { CurvyWithdrawalVerifier } from "../../../contracts/aggregator-beta/verifiers/CurvyWithdrawalVerifier.sol";
import { CurvyTypes as CurvyTypesV2 } from "../../../contracts/utils/TypesV2.sol";
import { CurvyTypes as CurvyTypesV1 } from "../../../contracts/utils/Types.sol";
import {
    WDR_MAX_INPUTS,
    WDR_TREE_DEPTH,
    WithdrawalFixtures
} from "./fixtures/withdrawal.fixtures.sol";

contract WithdrawalTest is Test {
    using stdStorage for StdStorage;

    CurvyAggregatorAlphaV2 public aggregator;
    CurvyVaultV1 public vault;
    CurvyWithdrawalVerifier public verifier;

    function setUp() public {
        // Aggregator proxy
        CurvyAggregatorAlphaV2 aggImpl = new CurvyAggregatorAlphaV2();
        bytes memory aggInit = abi.encodeCall(CurvyAggregatorAlphaV2.initialize, (address(this)));
        aggregator = CurvyAggregatorAlphaV2(address(new ERC1967Proxy(address(aggImpl), aggInit)));

        // Vault proxy
        CurvyVaultV1 vaultImpl = new CurvyVaultV1();
        bytes memory vaultInit = abi.encodeCall(CurvyVaultV1.initialize, (address(this)));
        vault = CurvyVaultV1(address(new ERC1967Proxy(address(vaultImpl), vaultInit)));

        // Wire vault <-> aggregator
        vault.setCurvyAggregatorAddress(address(aggregator));
        // Disable vault fees to keep accounting clean
        vault.setFeeAmount(CurvyTypesV1.FeeUpdate({ depositFee: 0, withdrawalFee: 0 }));

        aggregator.updateConfig(
            CurvyTypesV2.AggregatorConfigurationUpdate({
                curvyVault: address(vault),
                portalFactory: address(0)
            })
        );

        // Withdrawal verifier
        verifier = new CurvyWithdrawalVerifier();
        aggregator.setWithdrawalVerifier(WDR_MAX_INPUTS, WDR_TREE_DEPTH, address(verifier));

        // Fees set to 0 — withdrawnAmount stays fully payable to destination
        aggregator.setFees(0, 0);

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
            aggregator.getWithdrawalVerifier(WDR_MAX_INPUTS, WDR_TREE_DEPTH),
            address(verifier)
        );
        assertEq(vault.balanceOf(address(aggregator), fixture.tokenId), fixture.withdrawnAmount);
        assertEq(address(vault).balance, fixture.withdrawnAmount);
        assertTrue(aggregator.validNotesRoot(fixture.notesRoot));
    }

    function test_submitWithdrawalRequest() public {
        console.log("> Testing submitWithdrawalRequest withdraws 1500 wei (no fees) to destination");
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
            assertFalse(aggregator.withdrawalNullifiers(fixture.inputNullifiers[i]));
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

        // Net amount = withdrawnAmount (fees=0)
        uint256 netAmount = fixture.withdrawnAmount;

        // Funds reached destination
        assertEq(
            fixture.destinationAddress.balance,
            prevDestBalance + netAmount,
            "destination should receive net withdrawn amount"
        );
        // Vault ETH decreased by exactly net amount
        assertEq(
            address(vault).balance,
            prevVaultBalance - netAmount,
            "vault ETH balance should decrease by net amount"
        );
        // Aggregator's internal vault balance debited
        assertEq(
            vault.balanceOf(address(aggregator), fixture.tokenId),
            prevAggInternalBalance - netAmount,
            "aggregator internal vault balance should be debited"
        );

        // Nullifiers registered
        for (uint256 i = 0; i < WDR_MAX_INPUTS; i++) {
            if (fixture.inputNullifiers[i] == 0) continue;
            assertTrue(aggregator.withdrawalNullifiers(fixture.inputNullifiers[i]));
        }
        // Batch index advanced
        assertEq(aggregator.getCurrentNullifiersBatchIndex(), prevNullifierBatchIndex + 1);
    }

    function test_submitWithdrawalRequest_withGasFee() public {
        console.log("> Testing submitWithdrawalRequest with non-zero gasFee - relayer share + destination share");
        WithdrawalFixtures.Input memory fixture = WithdrawalFixtures.input();

        uint256 gasFee = 100;
        aggregator.setFees(0, gasFee);

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

        uint256 netAmount = fixture.withdrawnAmount - gasFee; // protocolFee=0
        assertEq(
            fixture.destinationAddress.balance,
            prevDestBalance + netAmount,
            "destination should receive net amount after gas fee"
        );
        assertEq(
            address(this).balance,
            prevRelayerBalance + gasFee,
            "relayer (msg.sender) should receive gas fee"
        );
    }

    receive() external payable {}
}
