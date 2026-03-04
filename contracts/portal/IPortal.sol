// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {CurvyTypes} from "../utils/Types.sol";

interface IPortal {
    //#region Errors

    error InvalidOwnerHashOrExitBridgeData();
    error InvalidLiFiAddress();
    error InvalidRecoveryAddress();
    error InvalidOwnerHash();
    error InsufficientBalanceForLiFiBridging();
    error InvalidSignatureOrTamperedData();
    error BridgeCallFailed();

    //#endregion

    //#region Events

    /// @notice Emitted when a shielding attempt fails
    event ShieldingFailed(uint256 indexed ownerHash, address indexed token, uint256 amount, string reason);

    //#endregion

    //#region Public functions

    function shield(
        CurvyTypes.Note memory note,
        address curvyAgrgegatorAlphaProxyAddress,
        address curvyVaultProxyAddress
    ) external;

    function bridge(address lifiDiamondAddress, bytes calldata bridgeData, uint256 amount, address currency) external;

    /**
     * @notice Used by the user to recover funds from the Portal.
     * @dev This is typically used when auto-shielding fails or if funds are accidentally sent to the Portal address.
     * @param tokenAddress The address of the token to recover.
     * @param to The address to send the recovered funds to.
     */
    function recover(address tokenAddress, address to) external;

    //#endregion
}
