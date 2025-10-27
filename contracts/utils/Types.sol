// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

library CurvyTypes {
    enum MetaTransactionType {Withdraw, Transfer, Deposit}

    struct MetaTransaction {
        address from;
        address to;
        uint256 tokenId;
        uint256 amount;
        uint256 gasFee;
        MetaTransactionType metaTransactionType;
    }

    struct AggregatorConfigurationUpdate {
        address admin;
        address insertionVerifier;
        address aggregationVerifier;
        address withdrawVerifier;
        address curvyVault;
    }

    struct Note {
        uint256 ownerHash;
        uint256 token;
        uint256 amount;
    }
}
