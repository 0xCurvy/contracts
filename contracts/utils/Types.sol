// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

library CurvyTypes {
    struct AggregatorConfigurationUpdate {
        address insertionVerifier;
        address aggregationVerifier;
        address withdrawVerifier;
        address curvyVault;
        address portalFactory;
        uint256 maxDeposits;
        uint256 maxWithdrawals;
        uint256 maxAggregations;
    }

    struct Note {
        uint256 ownerHash;
        uint256 token;
        uint256 amount;
    }

    struct FeeUpdate {
        uint96 depositFee;
        uint96 withdrawalFee;
    }
}
