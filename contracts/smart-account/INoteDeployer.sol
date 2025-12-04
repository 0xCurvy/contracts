// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {CurvyTypes} from "../utils/Types.sol";

interface INoteDeployer {
    //#region Errors

    error InvalidOwnerHash();

    //#endregion

    //#region Structs

    struct BridgeData {
        bytes32 transactionId;
        string bridge;
        string integrator;
        address referrer;
        address sendingAssetId;
        address receiver;
        uint256 minAmount;
        uint256 destinationChainId;
        bool hasSourceSwaps;
        bool hasDestinationCall;
    }

    //#endregion

    //#region Public functions

    function shield(
        CurvyTypes.Note memory note,
        address curvyAgrgegatorAlphaProxyAddress,
        address curvyVaultProxyAddress
    ) external;

    function bridge(
        address _lifiDiamondAddress,
        bytes calldata _bridgeData,
        CurvyTypes.Note memory note
    ) external payable;

    //#endregion
}
