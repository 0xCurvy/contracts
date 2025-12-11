// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {CurvyTypes} from "../utils/Types.sol";

interface IAirlock {
    //#region Errors

    error InvalidOwnerHash();

    //#endregion

    //#region Public functions

    function shield(
        CurvyTypes.Note memory note,
        address curvyAgrgegatorAlphaProxyAddress,
        address curvyVaultProxyAddress
    ) external;

    function bridge(
        address lifiDiamondAddress,
        bytes calldata bridgeData,
        CurvyTypes.Note memory note,
        address tokenAddress
    ) external;

    //#endregion
}
