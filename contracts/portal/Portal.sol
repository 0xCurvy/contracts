// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { CurvyTypes } from "../utils/Types.sol";
import { ICurvyAggregatorAlpha } from "../aggregator-alpha/ICurvyAggregatorAlpha.sol";
import { ICurvyVault } from "../vault/ICurvyVault.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IPortal } from "./IPortal.sol";
import { SingleUse } from "../utils/SingleUse.sol";

contract Portal is IPortal, SingleUse {
    using SafeERC20 for IERC20;

    uint256 private _ownerHash;
    address constant NATIVE_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    ICurvyAggregatorAlpha public curvyAggregator;
    ICurvyVault public curvyVault;

    address public recovery;

    modifier onlyRecovery() {
        require(msg.sender == recovery, "Portal: Only recovery");
        _;
    }

    constructor(uint256 ownerHash, address _recovery) {
        // TODO: add fee for deployment

        _ownerHash = ownerHash;
        recovery = _recovery;
    }

    function shield(
        CurvyTypes.Note memory note,
        address curvyAggregatorAlphaProxyAddress,
        address curvyVaultProxyAddress
    ) external onlyOnce {
        if (note.ownerHash != _ownerHash) {
            revert("Portal: Invalid owner hash");
        }

        curvyAggregator = ICurvyAggregatorAlpha(curvyAggregatorAlphaProxyAddress);
        curvyVault = ICurvyVault(curvyVaultProxyAddress);

        address tokenAddress;
        try curvyVault.getTokenAddress(note.token) returns (address _tokenAddress) {
            tokenAddress = _tokenAddress;
        } catch {
            // TODO: Emit shielding failed and if that event is detected in the simulation, then we will mark the shielding as failed.
            return; // Here we just do a return because we want the deployment to pass so that the user can call the recover method.
        }
        if (tokenAddress != address(0) && tokenAddress != NATIVE_ETH) {
            IERC20(tokenAddress).forceApprove(address(curvyAggregator), note.amount);
            curvyAggregator.autoShield(note, tokenAddress);
        } else {
            curvyAggregator.autoShield{ value: note.amount }(note, tokenAddress);
        }
    }

    function recover(address tokenAddress, address to) external onlyRecovery {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        if (tokenAddress == NATIVE_ETH) {
            (bool success, ) = to.call{ value: balance }("");
            require(success, "Portal: ETH transfer failed");
        } else {
            token.safeTransfer(to, balance);
        }
    }

    function bridge(
        address lifiDiamondAddress,
        bytes calldata bridgeData,
        CurvyTypes.Note memory note,
        address tokenAddress
    ) external onlyOnce {
        if (lifiDiamondAddress == address(0)) {
            revert("Portal: Invalid LI.FI address");
        }

        if (note.ownerHash != _ownerHash) {
            revert("Portal: Invalid owner hash");
        }

        uint256 amount = note.amount;

        if (tokenAddress != address(0) && tokenAddress != NATIVE_ETH) {
            IERC20(tokenAddress).forceApprove(lifiDiamondAddress, note.amount);
            amount = 0;
        }

        (bool success, ) = lifiDiamondAddress.call{ value: amount }(bridgeData);
        if (!success) {
            revert("Portal: Bridge call failed");
        }
    }
}
