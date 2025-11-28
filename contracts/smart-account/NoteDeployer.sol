pragma solidity ^0.8.28;

import { CurvyTypes } from "../utils/Types.sol";
import {ICurvyAggregatorAlpha} from "../aggregator-alpha/ICurvyAggregatorAlpha.sol";
import {ICurvyVault} from "../vault/ICurvyVault.sol";
import "hardhat/console.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NoteDeployer {
    using SafeERC20 for IERC20;

    ICurvyAggregatorAlpha public curvyAggregator;
    ICurvyVault public curvyVault;


    constructor(CurvyTypes.Note memory note, address curvyAggregatorAlphaProxyAddress, address curvyVaultProxyAddress) {
        // TODO: dodati fee za deployment
        curvyAggregator = ICurvyAggregatorAlpha(curvyAggregatorAlphaProxyAddress);
        curvyVault = ICurvyVault(curvyVaultProxyAddress);

        address tokenAddress = curvyVault.getTokenAddress(note.token);

        IERC20(tokenAddress).approve(curvyAggregatorAlphaProxyAddress, note.amount);

        curvyAggregator.autoShield(note);
    }
}

