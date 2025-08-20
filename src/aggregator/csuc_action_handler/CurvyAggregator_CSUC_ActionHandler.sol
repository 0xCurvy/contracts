// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ICSUC_ActionHandler, CSUC, CSUC_Types, IERC20, SafeERC20} from "../../csuc/Exports.sol";
import {CurvyAggregator_Types} from "../utils/_Types.sol";
import {CurvyAggregator_Constants} from "../utils/_Constants.sol";
import {ICurvyAggregator} from "../interface/ICurvyAggregator.sol";

/**
 * @title CurvyAggregator_CSUC_ActionHandler
 * @author Curvy Protocol (https://curvy.box)
 * @dev A contract that handles CSUC actions for the Curvy Aggregator.
 */
contract CurvyAggregator_CSUC_ActionHandler is ICSUC_ActionHandler, CSUC {
    /// @inheritdoc ICSUC_ActionHandler
    function handleAction(CSUC_Types.Action memory _action) external returns (bool _success) {
        if (_action.payload.actionId != getActionId()) return false;

        CSUC_Types.ActionPayload memory _payload = _action.payload;

        (CurvyAggregator_Types.Note[] memory _notes) = abi.decode(_payload.parameters, (CurvyAggregator_Types.Note[]));

        (uint256 _balanceBefore, uint256 _nonceBefore) =
            _unpackBalanceAndNonce(balanceAndNonce[_payload.token][_action.from]);

        balanceAndNonce[_payload.token][_action.from] =
            _packBalanceAndNonce(_balanceBefore - _payload.amount - _payload.totalFee, _nonceBefore + 1);

        if (_payload.token == CurvyAggregator_Constants.NATIVE_TOKEN) {
            require(
                ICurvyAggregator(aggregator).wrapNative{value: _payload.amount}(_notes),
                "CurvyAggregator_CSUC_ActionHandler: wrapNative failed"
            );
        } else {
            IERC20(_payload.token).safeIncreaseAllowance(aggregator, _payload.amount);
            require(
                ICurvyAggregator(aggregator).wrapERC20(_notes), "CurvyAggregator_CSUC_ActionHandler: wrapERC20 failed"
            );
            IERC20(_payload.token).safeDecreaseAllowance(aggregator, 0);
        }

        return true;
    }

    /// @inheritdoc ICSUC_ActionHandler
    function getActionId() public pure returns (uint256 _actionId) {
        return CurvyAggregator_Constants.CURVY_AGGREGATOR_CSUC_ACTION_HANDLER_ID;
    }

    using SafeERC20 for IERC20;
}
