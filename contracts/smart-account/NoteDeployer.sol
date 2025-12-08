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
    uint256 public constant MAX_SLIPPAGE_BPS = 500; // 1%
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
        address _lifiDiamondAddress,
        bytes calldata _bridgeData,
        CurvyTypes.Note memory note
    ) external payable {
        address tokenAddress = curvyVault.getTokenAddress(note.token);

        if (_lifiDiamondAddress == address(0)) {
            revert("NoteDeployer: Invalid LI.FI address");
        }

        if (_bridgeData.length < 4) {
            revert("NoteDeployer: Invalid bridge data");
        }

        (BridgeData memory bData) = abi.decode(_bridgeData[4:], (BridgeData));

        if (bData.receiver != address(this)) {
            revert("NoteDeployer: Invalid receiver");
        }

        // Token mismatch check
        // Sending asset in the struct must match input
        if (bData.sendingAssetId != tokenAddress) {
            revert("NoteDeployer: Token mismatch");
        }

        if (tokenAddress != address(0)) {
            if (bData.minAmount < note.amount) {
                uint256 slippage = ((note.amount - bData.minAmount) * 10000) /
                    note.amount;
                if (slippage > MAX_SLIPPAGE_BPS) {
                    revert("NoteDeployer: Slippage too high");
                }
            }
        }

        uint256 amount = note.amount;

        if (tokenAddress != address(0) && tokenAddress != NATIVE_ETH) {
            IERC20(tokenAddress).forceApprove(_lifiDiamondAddress, note.amount);
            amount = 0;
        }

        (bool success, ) = _lifiDiamondAddress.call{value: amount}(
            _bridgeData
        );
        if (!success) {
            revert("NoteDeployer: Bridge call failed");
        }
    }
}
