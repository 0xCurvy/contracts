// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import { CurvyTypes } from "../utils/Types.sol";
import { ICurvyAggregatorAlpha } from "../aggregator-alpha/ICurvyAggregatorAlpha.sol";
import { ICurvyVault } from "../vault/ICurvyVault.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { INoteDeployer } from "./INoteDeployer.sol";

contract NoteDeployer is INoteDeployer {
    using SafeERC20 for IERC20;

    uint256 private _ownerHash;

    ICurvyAggregatorAlpha public curvyAggregator;
    ICurvyVault public curvyVault;

    constructor(uint256 ownerHash) {
        // TODO: dodati fee za deployment

        _ownerHash = ownerHash;
    }

    function shield(CurvyTypes.Note memory note, address curvyAggregatorAlphaProxyAddress, address curvyVaultProxyAddress) external {
        require(note.ownerHash == _ownerHash, "Invalid owner hash");
        if (note.ownerHash != _ownerHash) revert InvalidOwnerHash();

        curvyAggregator = ICurvyAggregatorAlpha(curvyAggregatorAlphaProxyAddress);
        curvyVault = ICurvyVault(curvyVaultProxyAddress);

        address tokenAddress = curvyVault.getTokenAddress(note.token);

        IERC20(tokenAddress).approve(address(curvyAggregator), note.amount);

        curvyAggregator.autoShield(note);
    }
}

