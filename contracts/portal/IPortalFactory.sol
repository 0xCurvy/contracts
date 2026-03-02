// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { CurvyTypes } from "../utils/Types.sol";

interface IPortalFactory {
    //#region Errors

    error UnsupportedShielding();
    error DeploymentFailed();
    error UnsupportedBridging();

    //#endregion

    //#region Public functions

    function updateConfig(
        address curvyVaultProxyAddress,
        address curvyAggregatorAlphaProxyAddress,
        address lifiDiamondAddress
    ) external returns (bool);

    function getCreationCode(uint256 ownerHash, address exitAddress, uint256 exitChainId, address recovery) external pure returns (bytes memory);

    function getEntryPortalAddress(uint256 ownerHash, address recovery) external view returns (address);

    function getExitPortalAddress(address exitAddress, uint256 exitChainId, address recovery) external view returns (address);

    function portalIsRegistered(address portalAddress) external view returns (bool);

    function deployShieldPortal(CurvyTypes.Note memory note, address recovery) external payable;

    function deployEntryBridgePortal(
        bytes calldata bridgeData,
        CurvyTypes.Note memory note,
        address currency,
        address recovery
    ) external;

    function deployExitBridgePortal(
        bytes calldata bridgeData,
        uint256 amount,
        address currency,
        address exitAddress,
        uint256 exitChainId,
        address recovery
    ) external;

    //#endregion
}
