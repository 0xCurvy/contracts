// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { CurvyTypes } from "../utils/Types.sol";

interface IPortal {
    event ShieldingFailed(uint256 token);

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

    /**
     * @notice Used by the recipient to recover funds from the Portal.
     * @dev This is typically used when auto-shielding fails or if funds are accidentally sent to the Portal address.
     * @param tokenAddress The address of the token to recover.
     * @param to The address to send the recovered funds to.
     */
    function recover(address tokenAddress, address to) external;

    //#endregion
}
