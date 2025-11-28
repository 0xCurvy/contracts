pragma solidity 0.8.30;

import { CurvyTypes } from "../utils/Types.sol";
import {ICurvyAggregatorAlpha} from "../aggregator-alpha/ICurvyAggregatorAlpha.sol";
import {ICurvyVault} from "../vault/ICurvyVault.sol";

contract WalletDummy {
    address public owner;

    ICurvyAggregatorAlpha public curvyAggregator;

    constructor(CurvyTypes.Note memory note, address curvyAggregatorAlphaProxyAddress) {
        owner = note.ownerHash;
        // TODO: dodati fee za deployment
        curvyAggregator = ICurvyAggregatorAlpha(curvyAggregatorAlphaProxyAddress);

        curvyAggregator.depositNote(address(this), CurvyTypes.Note({
            ownerHash: note.ownerHash,
            amount: note.amount,
            token: note.token
        }));
    }
}

