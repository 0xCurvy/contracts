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
    error AlreadyInitialized();

    //#endregion

    //#region Public functions

    /// @notice One-time initializer called by the factory immediately after
    /// cloning the implementation. Mirrors the validation that used to run in
    /// the constructor. Reverts on the second call against the same proxy and
    /// on any call against the implementation itself.
    function initialize(uint256 ownerHash, address exitAddress, uint256 exitChainId, address recovery) external;

    function shield(
        CurvyTypes.Note memory note,
        address curvyAggregatorAlphaProxyAddress,
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
