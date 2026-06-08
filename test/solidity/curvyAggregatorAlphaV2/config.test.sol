// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {
    ERC1967Proxy
} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {CurvyTypes} from "../../../contracts/utils/TypesV2.sol";
import {
    CurvyAggregatorAlphaV2
} from "../../../contracts/aggregator-beta/CurvyAggregatorAlphaV2.sol";
import {CurvyVaultV1} from "../../../contracts/vault/CurvyVaultV1.sol";

uint256 constant EMPTY_TREE_ROOT = 4114686047564160449611603615418567457008101555090703535405891656262658644463;

contract CurvyAggregatorAlphaV2TestConfig is Test {
    CurvyAggregatorAlphaV2 public curvyAggregatorAlphaV2;
    CurvyVaultV1 public mockCurvyVault;

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

        // Deploy a mock curvy vault
        mockCurvyVault = new CurvyVaultV1();
    }

    /// @dev Test the default config of the curvyAggregatorAlphaV2
    function test_curvyAggregatorAlphaV2_default_config() public view {
        console.log("> Testing default config of the curvyAggregatorAlphaV2");

        // Check default config
        assertEq(
            curvyAggregatorAlphaV2.protocolFeePerThousand(),
            0,
            "protocolFeePerThousand should be 0"
        );
        assertEq(curvyAggregatorAlphaV2.gasFee(), 0, "gasFee should be 0");
        assertEq(
            curvyAggregatorAlphaV2.feeNotePublicKey(0),
            0,
            "feeNotePublicKey[0] should be 0"
        );
        assertEq(
            curvyAggregatorAlphaV2.feeNotePublicKey(1),
            0,
            "feeNotePublicKey[1] should be 0"
        );

        // Check  default verifiers
        assertEq(
            address(
                curvyAggregatorAlphaV2.getPendingNotesCommitmentVerifier(
                    100,
                    100
                )
            ),
            address(0),
            "getPendingNotesCommitmentVerifier(100, 100) should be 0"
        );
        assertEq(
            address(
                curvyAggregatorAlphaV2.getAggregationVerifier(100, 100, 100)
            ),
            address(0),
            "getAggregationVerifier(100, 100, 100) should be 0"
        );
        assertEq(
            address(curvyAggregatorAlphaV2.getWithdrawalVerifier(100, 100)),
            address(0),
            "getWithdrawalVerifier(100, 100) should be 0"
        );

        assertEq(
            curvyAggregatorAlphaV2.getCurrentNotesTreeRoot(),
            EMPTY_TREE_ROOT,
            "getCurrentNotesTreeRoot should be 0"
        );
        assertEq(
            curvyAggregatorAlphaV2.getCurrentNotesBatchIndex(),
            0,
            "getCurrentNotesBatchIndex should be 0"
        );
        assertEq(
            curvyAggregatorAlphaV2.getCurrentNullifiersBatchIndex(),
            0,
            "getCurrentNullifiersBatchIndex should be 0"
        );
        assertEq(
            curvyAggregatorAlphaV2.getCurrentNoteIndex(),
            0,
            "getCurrentNoteIndex should be 0"
        );
    }

    /// @dev Test the update config of the curvyAggregatorAlphaV2
    function test_curvyAggregatorAlphaV2_update_config() public {
        console.log("> Testing update config of the curvyAggregatorAlphaV2");

        // Update config
        curvyAggregatorAlphaV2.updateConfig(
            CurvyTypes.AggregatorConfigurationUpdate({
                curvyVault: address(mockCurvyVault),
                portalFactory: address(0)
            })
        );

        // Set fees
        curvyAggregatorAlphaV2.setFees(1000, 1000);
        curvyAggregatorAlphaV2.setFeeNotePublicKey(0, 0);

        // Set pending notes commitment verifier
        curvyAggregatorAlphaV2.setPendingNotesCommitmentVerifier(
            100,
            100,
            address(123)
        );

        // Set aggregation verifier
        curvyAggregatorAlphaV2.setAggregationVerifier(
            100,
            100,
            100,
            address(456)
        );

        // Set withdrawal verifier
        curvyAggregatorAlphaV2.setWithdrawalVerifier(100, 100, address(789));

        // Check curvy vault and portal factory
        assertEq(
            address(curvyAggregatorAlphaV2.curvyVault()),
            address(mockCurvyVault),
            "curvyVault should be mockCurvyVault"
        );
        assertEq(
            address(curvyAggregatorAlphaV2.portalFactory()),
            address(0),
            "portalFactory should be 0"
        );

        // Check fees
        assertEq(
            curvyAggregatorAlphaV2.protocolFeePerThousand(),
            1000,
            "protocolFeePerThousand should be 1000"
        );
        assertEq(
            curvyAggregatorAlphaV2.gasFee(),
            1000,
            "gasFee should be 1000"
        );

        // Check fee note public key
        assertEq(
            curvyAggregatorAlphaV2.feeNotePublicKey(0),
            0,
            "feeNotePublicKey[0] should be 0"
        );
        assertEq(
            curvyAggregatorAlphaV2.feeNotePublicKey(1),
            0,
            "feeNotePublicKey[1] should be 0"
        );

        // Check verifier addresses
        assertEq(
            curvyAggregatorAlphaV2.getPendingNotesCommitmentVerifier(100, 100),
            address(123),
            "getPendingNotesCommitmentVerifier(100, 100) should be 123"
        );
        assertEq(
            curvyAggregatorAlphaV2.getAggregationVerifier(100, 100, 100),
            address(456),
            "getAggregationVerifier(100, 100, 100) should be 456"
        );
        assertEq(
            curvyAggregatorAlphaV2.getWithdrawalVerifier(100, 100),
            address(789),
            "getWithdrawalVerifier(100, 100) should be 789"
        );
    }
}
