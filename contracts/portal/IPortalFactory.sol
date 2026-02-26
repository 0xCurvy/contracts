// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { CurvyTypes } from "../utils/Types.sol";

interface IPortalFactory {
    function updateConfig(
        address curvyVaultProxyAddress,
        address curvyAggregatorAlphaProxyAddress,
        address lifiDiamondAddress
    ) external returns (bool);

    function getCreationCode(uint256 ownerHash, address recovery) external pure returns (bytes memory);

    function getPortalAddress(uint256 ownerHash, address recovery) external view returns (address);

    function portalIsRegistered(address portalAddress) external view returns (bool);

    function deployAndShield(CurvyTypes.Note memory note, address recovery) external payable;

    function deployAndBridge(
        bytes calldata bridgeData,
        CurvyTypes.Note memory note,
        address recovery
    ) external;

    function deployAndExitBridge(
        bytes calldata bridgeData,
        uint256 amount,
        address recovery
    ) external;
}
