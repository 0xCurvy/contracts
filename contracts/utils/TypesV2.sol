// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

library CurvyTypes {
    struct AggregatorConfigurationUpdate {
        address curvyVault;
        address portalFactory;
    }

    struct Note {
        uint256 ownerHash;
        uint256 token;
        uint256 amount;
        uint256[2] ephemeralKey; // [x, y]
        uint16 viewTag; // 16 bits
    }

    struct OutputNote {
        uint256 noteId;
        uint256 encryptedAmount;
        uint256 encryptedTokenId;
        uint256[] ephemeralKey; // [x, y]
        uint16 viewTag;
    }

    struct FeeUpdate {
        uint96 depositFee;
        uint96 withdrawalFee;
    }
}
