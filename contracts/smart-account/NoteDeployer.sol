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
    uint256 public constant MAX_SLIPPAGE_BPS = 100; // 1%
    uint256 private ARBITRUM_CHAIN_ID = 42161;
    uint256 private SEPOLIA_CHAIN_ID = 11155111;

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
        if (
            block.chainid != ARBITRUM_CHAIN_ID &&
            block.chainid != SEPOLIA_CHAIN_ID
        ) {
            revert("NoteDeployer: Shielding not supported on this chain");
        }

        require(note.ownerHash == _ownerHash, "Invalid owner hash");
        if (note.ownerHash != _ownerHash) revert InvalidOwnerHash();

        curvyAggregator = ICurvyAggregatorAlpha(
            curvyAggregatorAlphaProxyAddress
        );
        curvyVault = ICurvyVault(curvyVaultProxyAddress);

        address tokenAddress = curvyVault.getTokenAddress(note.token);

        IERC20(tokenAddress).approve(address(curvyAggregator), note.amount);

        curvyAggregator.autoShield(note);
    }

    function bridge(
        address _lifiDiamondAddress,
        bytes calldata _bridgeData,
        CurvyTypes.Note memory note
    ) external payable {
        if (
            block.chainid == ARBITRUM_CHAIN_ID ||
            block.chainid == SEPOLIA_CHAIN_ID
        ) {
            revert("NoteDeployer: Bridging not supported on this chain");
        }

        address tokenAddress = curvyVault.getTokenAddress(note.token);

        if (_lifiDiamondAddress == address(0)) {
            revert("NoteDeployer: Invalid LI.FI address");
        }

        if (_bridgeData.length < 4) {
            revert("NoteDeployer: Invalid bridge data");
        }

        (BridgeData memory bData) = abi.decode(_bridgeData[4:], (BridgeData));

        if (bData.hasSourceSwaps) {
            revert("NoteDeployer: Source swaps not supported");
        }

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

        if (tokenAddress != address(0)) {
            IERC20(tokenAddress).forceApprove(_lifiDiamondAddress, note.amount);
        } else {
            require(msg.value >= note.amount, "Insufficient ETH sent");
        }

        (bool success, ) = _lifiDiamondAddress.call{value: msg.value}(
            _bridgeData
        );
        if (!success) {
            revert("NoteDeployer: Bridge call failed");
        }
    }
}
