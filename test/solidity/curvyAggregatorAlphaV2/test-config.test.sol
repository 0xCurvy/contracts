// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { CurvyTypes } from "../../../contracts/utils/Types.sol";
import { CurvyAggregatorAlphaV2 } from "../../../contracts/aggregator-beta/CurvyAggregatorAlphaV2.sol";
import { CurvyVaultV1 } from "../../../contracts/vault/CurvyVaultV1.sol";

contract CurvyAggregatorAlphaV2TestConfig is Test {
    CurvyAggregatorAlphaV2 public curvyAggregatorAlphaV2;
    CurvyVaultV1 public mockCurvyVault;

    function setUp() public {
        CurvyAggregatorAlphaV2 implementation = new CurvyAggregatorAlphaV2();
        bytes memory initData = abi.encodeCall(CurvyAggregatorAlphaV2.initialize, (address(this)));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        curvyAggregatorAlphaV2 = CurvyAggregatorAlphaV2(address(proxy));

        // Deploy a mock curvy vault
        mockCurvyVault = new CurvyVaultV1();
    }

    /// @dev Test the default config of the curvyAggregatorAlphaV2
    function test_curvyAggregatorAlphaV2_default_config() public view {
        console.log('> Testing default config of the curvyAggregatorAlphaV2');
        
        assertEq(curvyAggregatorAlphaV2.maxDeposits(), 0, "maxDeposits should be 0");
        assertEq(curvyAggregatorAlphaV2.maxAggregations(), 0, "maxAggregations should be 0");
        assertEq(curvyAggregatorAlphaV2.maxWithdrawals(), 0, "maxWithdrawals should be 0");
        assertEq(curvyAggregatorAlphaV2.protocolFeePerThousand(), 0, "protocolFeePerThousand should be 0");
        assertEq(curvyAggregatorAlphaV2.gasFee(), 0, "gasFee should be 0");
        assertEq(curvyAggregatorAlphaV2.feeNotePublicKey(0), 0, "feeNotePublicKey[0] should be 0");
        assertEq(curvyAggregatorAlphaV2.feeNotePublicKey(1), 0, "feeNotePublicKey[1] should be 0");
    }

    /// @dev Test the update config of the curvyAggregatorAlphaV2
    function test_curvyAggregatorAlphaV2_update_config() public {
        console.log('> Testing update config of the curvyAggregatorAlphaV2');

        curvyAggregatorAlphaV2.updateConfig(
            CurvyTypes.AggregatorConfigurationUpdate({
                insertionVerifier: address(0),
                aggregationVerifier: address(0),
                withdrawVerifier: address(0),
                curvyVault: address(mockCurvyVault),
                portalFactory: address(0),
                maxDeposits: 100,
                maxWithdrawals: 100,
                maxAggregations: 100
            })
        );
        curvyAggregatorAlphaV2.setFees(1000, 1000);
        curvyAggregatorAlphaV2.setFeeNotePublicKey(0, 0);
    
        // address insertionVerifier = address(curvyAggregatorAlphaV2.insertionVerifier());
        // assertEq(insertionVerifier, address(123), "insertionVerifier should be 123");
        // address aggregationVerifier = address(curvyAggregatorAlphaV2.aggregationVerifier());
        // assertEq(aggregationVerifier, address(0), "aggregationVerifier should be 0");
        // address withdrawVerifier = address(curvyAggregatorAlphaV2.withdrawVerifier());
        // assertEq(withdrawVerifier, address(0), "withdrawVerifier should be 0");
        assertEq(address(curvyAggregatorAlphaV2.curvyVault()), address(mockCurvyVault), "curvyVault should be mockCurvyVault");
        assertEq(address(curvyAggregatorAlphaV2.portalFactory()), address(0), "portalFactory should be 0");
        assertEq(curvyAggregatorAlphaV2.maxDeposits(), 100, "maxDeposits should be 100");
        assertEq(curvyAggregatorAlphaV2.maxAggregations(), 100, "maxAggregations should be 100");
        assertEq(curvyAggregatorAlphaV2.maxWithdrawals(), 100, "maxWithdrawals should be 100");
        assertEq(curvyAggregatorAlphaV2.protocolFeePerThousand(), 1000, "protocolFeePerThousand should be 1000");
        assertEq(curvyAggregatorAlphaV2.gasFee(), 1000, "gasFee should be 1000");
        assertEq(curvyAggregatorAlphaV2.feeNotePublicKey(0), 0, "feeNotePublicKey[0] should be 0");
        assertEq(curvyAggregatorAlphaV2.feeNotePublicKey(1), 0, "feeNotePublicKey[1] should be 0");
    }
}
