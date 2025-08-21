// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ICSUC_ActionHandler, CSUC, CSUC_Types, IERC20, SafeERC20} from "../../csuc/Exports.sol";
import {CurvyAggregator_Types} from "../utils/_Types.sol";
import {CurvyAggregator_Constants} from "../utils/_Constants.sol";
import {ICurvyAggregator_NoAssetTransfer} from "../interface/ICurvyAggregator_NoAssetTransfer.sol";

/**
 * @title CurvyAggregator_CSUC_NoAssetTransfer_ActionHandler
 * @author Curvy Protocol (https://curvy.box)
 * @dev A contract that handles CSUC actions for the Curvy Aggregator without asset transfers.
 */
contract CurvyAggregator_CSUC_NoAssetTransfer_ActionHandler is ICSUC_ActionHandler, CSUC {
    /// @inheritdoc ICSUC_ActionHandler
    function handleAction(CSUC_Types.Action memory _action) external returns (bool _success) {
        if (_action.payload.actionId != getActionId()) return false;

        CSUC_Types.ActionPayload memory _payload = _action.payload;

        (CurvyAggregator_Types.Note[] memory _notes) = abi.decode(_payload.parameters, (CurvyAggregator_Types.Note[]));

        if (!_fromHasEnoughAssets(_payload.token, _action.from, _payload.amount + _payload.totalFee)) {
            return false;
        }

        if (!_noteAmountSumIsValid(_notes, _payload.amount)) {
            return false;
        }

        if (!_notesHaveTheSameToken(_notes) || address(uint160(_notes[0].token)) != _payload.token) {
            return false;
        }

        // Sender's balance gets decreased
        (uint256 _senderBalanceBefore, uint256 _senderNonceBefore) =
            _unpackBalanceAndNonce(balanceAndNonce[_payload.token][_action.from]);

        balanceAndNonce[_payload.token][_action.from] =
            _packBalanceAndNonce(_senderBalanceBefore - _payload.amount - _payload.totalFee, _senderNonceBefore + 1);

        // Aggregator's balance gets increased
        address _aggregatorCached = aggregator;

        (uint256 _aggregatorBalanceBefore, uint256 _aggregatorNonceBefore) =
            _unpackBalanceAndNonce(balanceAndNonce[_payload.token][_aggregatorCached]);
        balanceAndNonce[_payload.token][_aggregatorCached] =
            _packBalanceAndNonce(_aggregatorBalanceBefore + _payload.amount, _aggregatorNonceBefore);

        _success = ICurvyAggregator_NoAssetTransfer(_aggregatorCached).wrap(_notes);
    }

    /// @inheritdoc ICSUC_ActionHandler
    function getActionId() public pure returns (uint256 _actionId) {
        return CurvyAggregator_Constants.CURVY_AGGREGATOR_CSUC_ACTION_HANDLER_ID;
    }

    function _noteAmountSumIsValid(CurvyAggregator_Types.Note[] memory _notes, uint256 _amount)
        internal
        pure
        returns (bool)
    {
        uint256 _sum;
        for (uint256 i; i < _notes.length; ++i) {
            _sum += _notes[i].amount;
        }
        return _sum == _amount;
    }

    function _notesHaveTheSameToken(CurvyAggregator_Types.Note[] memory _notes) internal pure returns (bool) {
        if (_notes.length == 0) return true;

        uint256 _token = _notes[0].token;
        for (uint256 i; i < _notes.length; ++i) {
            if (_notes[i].token != _token) return false;
        }
        return true;
    }

    using SafeERC20 for IERC20;
}
