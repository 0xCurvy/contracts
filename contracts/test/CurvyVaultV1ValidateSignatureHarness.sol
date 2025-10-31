// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {CurvyVaultV1} from "../vault/CurvyVaultV1.sol";
import { CurvyTypes } from "../utils/Types.sol";

contract CurvyVaultV1ValidateSignatureHarness is CurvyVaultV1 {
    function _validateSignature_Harness(CurvyTypes.MetaTransaction calldata metaTransaction, bytes memory signature) external {
        super._validateSignature(metaTransaction, signature);
    }
}