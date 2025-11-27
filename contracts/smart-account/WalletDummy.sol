pragma solidity 0.8.30;

import { CurvyTypes } from "../utils/Types.sol";
import {ICurvyAggregatorAlpha} from "../aggregator-alpha/ICurvyAggregatorAlpha.sol";

contract WalletDummy {
    address public owner;

    ICurvyAggregatorAlpha public curvyAggregator;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    event Transfer(address recipient, uint256 amount);

    constructor(CurvyTypes.Note memory note) {
        owner = note.ownerHash;
        // ownerHash da se proveri (hardcoded)
        // dodati fee za deployment
        // uraditi deposit note na aggregator
        curvyAggregator.depositNote(address(this), CurvyTypes.Note({
            ownerHash: note.ownerHash,
            amount: note.amount,
            token: note.token
        }), "0x0");
    }

    function transfer(address recipient, uint256 amount) public onlyOwner {
        emit Transfer(recipient, amount);
    }
}

