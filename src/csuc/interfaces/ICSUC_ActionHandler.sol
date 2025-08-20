// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {CSUC_Types} from "../utils/_Types.sol";
import {CSUC_Constants} from "../utils/_Constants.sol";

/**
 * @title ICSUC_ActionHandler
 * @author Curvy Protocol (https://curvy.box/)
 * @notice Interface for contracts handling CSUC actions.
 * @dev Action handlers are meant to be called via delegatecall from the CSUC contract.
 */
interface ICSUC_ActionHandler {
    /**
     * @notice Handles a CSUC action.
     * @dev CSUC actions must increment nonce before the .delegatecall ends.
     * @param _action The custom action to be handled.
     * @return _success Returns true if the action was handled successfully, false otherwise.
     */
    function handleAction(CSUC_Types.Action memory _action) external returns (bool _success);

    /**
     * @notice Returns the handler's Action ID.
     * @return _actionId Returns the Action ID.
     */
    function getActionId() external view returns (uint256 _actionId);
}
