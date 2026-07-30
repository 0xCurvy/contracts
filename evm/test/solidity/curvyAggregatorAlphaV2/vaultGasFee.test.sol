// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {CurvyAggregatorAlphaV2} from "../../../src/v2/aggregator-alpha/CurvyAggregatorAlphaV2.sol";
import {ICurvyAggregatorAlpha} from "../../../src/v2/aggregator-alpha/ICurvyAggregatorAlpha.sol";
import {CurvyVaultV2} from "../../../src/v2/vault/CurvyVaultV2.sol";
import {ICurvyVault} from "../../../src/v2/vault/ICurvyVault.sol";
import {CurvyTypes} from "../../../src/v2/utils/Types.sol";

/// @dev Per-token gas-fee setters live on the vault now. setCommitmentGasFee stores the table and
///      pushes the single root to the aggregator (onlyCurvyVault); setWithdrawalGasFee is vault-only.
contract VaultGasFeeTest is Test {
    CurvyAggregatorAlphaV2 public aggregator;
    CurvyVaultV2 public vault;

    function setUp() public {
        CurvyAggregatorAlphaV2 aggImpl = new CurvyAggregatorAlphaV2();
        aggregator = CurvyAggregatorAlphaV2(
            address(
                new ERC1967Proxy(
                    address(aggImpl),
                    abi.encodeCall(CurvyAggregatorAlphaV2.initialize, (address(this)))
                )
            )
        );

        CurvyVaultV2 vaultImpl = new CurvyVaultV2();
        vault = CurvyVaultV2(
            address(
                new ERC1967Proxy(address(vaultImpl), abi.encodeCall(CurvyVaultV2.initialize, (address(this))))
            )
        );

        // Bidirectional wiring: vault must know the aggregator (to push the root), and the
        // aggregator must accept the root only from this vault (onlyCurvyVault).
        vault.setCurvyAggregatorAddress(address(aggregator));
        aggregator.updateConfig(
            CurvyTypes.AggregatorConfigurationUpdate({curvyVault: address(vault), portalFactory: address(0)})
        );
    }

    function _fullTable() internal view returns (uint256[] memory tokenIds, uint256[] memory costs) {
        uint256 width = 1 << aggregator.GAS_TREE_DEPTH();
        tokenIds = new uint256[](width);
        costs = new uint256[](width);
        for (uint256 i = 0; i < width; i++) {
            tokenIds[i] = i;
            costs[i] = (i + 1) * 10;
        }
    }

    function test_setWithdrawalGasFee() public {
        console.log("> Testing vault.setWithdrawalGasFee");
        uint256[] memory tokenIds = new uint256[](2);
        uint256[] memory costs = new uint256[](2);
        tokenIds[0] = 1;
        costs[0] = 111;
        tokenIds[1] = 7;
        costs[1] = 777;

        vault.setWithdrawalGasFee(tokenIds, costs);
        assertEq(vault.withdrawalGasCost(1), 111, "tokenId 1 withdrawal cost");
        assertEq(vault.withdrawalGasCost(7), 777, "tokenId 7 withdrawal cost");
        assertEq(vault.withdrawalGasCost(2), 0, "unset token defaults to 0");

        uint256[] memory mismatched = new uint256[](1);
        vm.expectRevert(ICurvyVault.GasCostLengthMismatch.selector);
        vault.setWithdrawalGasFee(tokenIds, mismatched);
    }

    function test_setCommitmentGasFee() public {
        console.log("> Testing vault.setCommitmentGasFee (full table + root push to aggregator)");
        (uint256[] memory tokenIds, uint256[] memory costs) = _fullTable();
        uint256 root = 0xABCDEF;

        vault.setCommitmentGasFee(tokenIds, costs, root);

        assertEq(vault.commitmentGasCost(1), costs[1], "tokenId 1 commitment cost stored on vault");
        assertEq(aggregator.commitmentFeeRoot(), root, "root pushed to aggregator");
        assertEq(vault.latestCommitmentGasCostUpdateBlock(), block.number, "update block pointer set");
    }

    function test_setCommitmentGasFee_reverts() public {
        console.log("> Testing vault.setCommitmentGasFee reverts");
        (uint256[] memory tokenIds, uint256[] memory costs) = _fullTable();

        // root == 0
        vm.expectRevert(ICurvyVault.InvalidGasFeeRoot.selector);
        vault.setCommitmentGasFee(tokenIds, costs, 0);

        // table not exactly 2^GAS_TREE_DEPTH
        uint256[] memory shortCosts = new uint256[](costs.length - 1);
        uint256[] memory shortIds = new uint256[](costs.length - 1);
        vm.expectRevert(ICurvyVault.GasCostLengthMismatch.selector);
        vault.setCommitmentGasFee(shortIds, shortCosts, 1);

        // tokenIds / costs length mismatch
        uint256[] memory oneId = new uint256[](1);
        vm.expectRevert(ICurvyVault.GasCostLengthMismatch.selector);
        vault.setCommitmentGasFee(oneId, costs, 1);
    }

    function test_setCommitmentGasFeeRoot_onlyCurvyVault() public {
        console.log("> Testing aggregator.setCommitmentGasFeeRoot rejects non-vault callers");
        // address(this) is the authority but NOT the wired curvyVault → must revert.
        vm.expectRevert(ICurvyAggregatorAlpha.NotCurvyVault.selector);
        aggregator.setCommitmentGasFeeRoot(123);
    }
}
