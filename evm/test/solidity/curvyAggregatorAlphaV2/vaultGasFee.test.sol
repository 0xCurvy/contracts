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

/// @dev `registerToken` only requires the address to have code; this stands in for an ERC-20.
contract TokenStub {}

/// @dev Per-token gas fees live on the vault. `setPerTokenGasFees` writes the portal-deployment,
///      pending-note-commitment and withdrawal costs for the REGISTERED tokens and pushes the
///      single commitment-tree root to the aggregator, which accepts it only from its wired vault.
contract VaultGasFeeTest is Test {
    CurvyAggregatorAlphaV2 public aggregator;
    CurvyVaultV2 public vault;

    /// Registered token count after `setUp` — `initialize` reserves tokenId 1 (the native asset)
    /// and the two stubs below take ids 2 and 3.
    uint256 internal constant REGISTERED = 3;

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

        vault.registerToken(address(new TokenStub())); // tokenId 2
        vault.registerToken(address(new TokenStub())); // tokenId 3
    }

    function _fees(uint256 tokenId) internal pure returns (CurvyTypes.GasFees memory) {
        return
            CurvyTypes.GasFees({
                tokenId: tokenId,
                portalDeployment: tokenId * 100,
                pendingNoteCommitment: tokenId * 10,
                withdrawal: tokenId
            });
    }

    /// One entry per registered token, ascending — the shape callers are expected to publish so a
    /// single `CommitmentGasCostsUpdated` event is self-sufficient.
    function _fullSet() internal pure returns (CurvyTypes.GasFees[] memory gasFees) {
        gasFees = new CurvyTypes.GasFees[](REGISTERED);
        for (uint256 i = 0; i < REGISTERED; i++) {
            gasFees[i] = _fees(i + 1);
        }
    }

    function test_setPerTokenGasFees() public {
        console.log("> Testing vault.setPerTokenGasFees (registered set + root push to aggregator)");
        uint256 root = 0xABCDEF;

        vault.setPerTokenGasFees(_fullSet(), root);

        for (uint256 tokenId = 1; tokenId <= REGISTERED; tokenId++) {
            CurvyTypes.GasFees memory stored = vault.perTokenGasFees(tokenId);
            assertEq(stored.portalDeployment, tokenId * 100, "portalDeployment stored on vault");
            assertEq(stored.pendingNoteCommitment, tokenId * 10, "pendingNoteCommitment stored on vault");
            assertEq(stored.withdrawal, tokenId, "withdrawal stored on vault");
        }

        assertEq(aggregator.commitmentFeeRoot(), root, "root pushed to aggregator");
        assertEq(vault.gasFeeUpdateBlock(), block.number, "update block pointer set");
    }

    /// A short set is legal — leaves past it keep whatever they held, and the buffer stays zero.
    function test_setPerTokenGasFees_partialSetIsAllowed() public {
        console.log("> Testing vault.setPerTokenGasFees accepts fewer entries than registered");
        CurvyTypes.GasFees[] memory gasFees = new CurvyTypes.GasFees[](1);
        gasFees[0] = _fees(1);

        vault.setPerTokenGasFees(gasFees, 1);

        assertEq(vault.perTokenGasFees(1).pendingNoteCommitment, 10, "tokenId 1 written");
        assertEq(vault.perTokenGasFees(3).pendingNoteCommitment, 0, "tokenId 3 untouched");
    }

    function test_setPerTokenGasFees_reverts() public {
        console.log("> Testing vault.setPerTokenGasFees reverts");

        // root == 0
        vm.expectRevert(ICurvyVault.InvalidGasFeeRoot.selector);
        vault.setPerTokenGasFees(_fullSet(), 0);

        // more entries than registered tokens
        CurvyTypes.GasFees[] memory tooMany = new CurvyTypes.GasFees[](REGISTERED + 1);
        for (uint256 i = 0; i < REGISTERED + 1; i++) {
            tooMany[i] = _fees(i + 1);
        }
        vm.expectRevert(ICurvyVault.GasFeesLengthMismatch.selector);
        vault.setPerTokenGasFees(tooMany, 1);

        // tokenId 0 is the unused leaf, never a real token
        CurvyTypes.GasFees[] memory zeroId = new CurvyTypes.GasFees[](1);
        zeroId[0] = _fees(0);
        vm.expectRevert(ICurvyVault.TokenNotRegistered.selector);
        vault.setPerTokenGasFees(zeroId, 1);

        // tokenId past the registered range
        CurvyTypes.GasFees[] memory unknownId = new CurvyTypes.GasFees[](1);
        unknownId[0] = _fees(REGISTERED + 1);
        vm.expectRevert(ICurvyVault.TokenNotRegistered.selector);
        vault.setPerTokenGasFees(unknownId, 1);

        // descending tokenIds
        CurvyTypes.GasFees[] memory unsorted = new CurvyTypes.GasFees[](2);
        unsorted[0] = _fees(3);
        unsorted[1] = _fees(2);
        vm.expectRevert(ICurvyVault.UnsortedOrDuplicateTokenId.selector);
        vault.setPerTokenGasFees(unsorted, 1);

        // duplicate tokenIds
        CurvyTypes.GasFees[] memory duplicate = new CurvyTypes.GasFees[](2);
        duplicate[0] = _fees(2);
        duplicate[1] = _fees(2);
        vm.expectRevert(ICurvyVault.UnsortedOrDuplicateTokenId.selector);
        vault.setPerTokenGasFees(duplicate, 1);

        // a cost that does not fit the packed uint128 slot
        CurvyTypes.GasFees[] memory tooLarge = new CurvyTypes.GasFees[](1);
        tooLarge[0] = CurvyTypes.GasFees({
            tokenId: 1,
            portalDeployment: uint256(type(uint128).max) + 1,
            pendingNoteCommitment: 0,
            withdrawal: 0
        });
        vm.expectRevert(ICurvyVault.GasFeeTooLarge.selector);
        vault.setPerTokenGasFees(tooLarge, 1);
    }

    function test_setCommitmentGasFeeRoot_onlyCurvyVault() public {
        console.log("> Testing aggregator.setCommitmentGasFeeRoot rejects non-vault callers");
        // address(this) is the authority but NOT the wired curvyVault → must revert.
        vm.expectRevert(ICurvyAggregatorAlpha.NotCurvyVault.selector);
        aggregator.setCommitmentGasFeeRoot(123);
    }
}
