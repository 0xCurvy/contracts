// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {CurvyTypes} from "../utils/Types.sol";
import {
    ICurvyAggregatorAlpha
} from "../aggregator-alpha/ICurvyAggregatorAlpha.sol";
import {ICurvyVault} from "../vault/ICurvyVault.sol";
import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {INoteDeployer} from "./INoteDeployer.sol";

contract NoteDeployer is INoteDeployer {
    using SafeERC20 for IERC20;

    uint256 private _ownerHash;
    address constant NATIVE_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    //#region Errors

    ICurvyAggregatorAlpha public curvyAggregator;
    ICurvyVault public curvyVault;

    constructor(uint256 ownerHash) {
        // TODO: dodati fee za deployment

        _ownerHash = ownerHash;
    }

    function shield(
        CurvyTypes.Note memory note,
        address curvyAggregatorAlphaProxyAddress,
        address curvyVaultProxyAddress
    ) external {
        require(note.ownerHash == _ownerHash, "Invalid owner hash");

        curvyAggregator = ICurvyAggregatorAlpha(
            curvyAggregatorAlphaProxyAddress
        );
        curvyVault = ICurvyVault(curvyVaultProxyAddress);

        address tokenAddress = curvyVault.getTokenAddress(note.token);

        if (tokenAddress != address(0) && tokenAddress != NATIVE_ETH) {
            IERC20(tokenAddress).forceApprove(
                address(curvyAggregator),
                note.amount
            );
            curvyAggregator.autoShield(note, tokenAddress);
        } else {
            curvyAggregator.autoShield{value: note.amount}(note, tokenAddress);
        }
    }

    function bridge(
        address lifiDiamondAddress,
        bytes calldata bridgeData,
        CurvyTypes.Note memory note,
        address tokenAddress
    ) external {
        if (lifiDiamondAddress == address(0)) {
            revert("NoteDeployer: Invalid LI.FI address");
        }

        uint256 amount = note.amount;

        if (tokenAddress != address(0) && tokenAddress != NATIVE_ETH) {
            IERC20(tokenAddress).forceApprove(lifiDiamondAddress, note.amount);
            amount = 0;
        }

        (bool success, ) = lifiDiamondAddress.call{value: amount}(bridgeData);
        if (!success) {
            revert("NoteDeployer: Bridge call failed");
        }
    }
}
