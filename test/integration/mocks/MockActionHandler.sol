// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {CSUC, ERC1155Upgradeable, ReentrancyGuardWithInitializer} from "../../../src/csuc/CSUC.sol";
import {ICSUC_ActionHandler} from "../../../src/csuc/interfaces/ICSUC_ActionHandler.sol";
import {CSUC_Types} from "../../../src/csuc/utils/_Types.sol";
import {CSUC_Constants} from "../../../src/csuc/utils/_Constants.sol";

/**
 * @title MockActionHandler
 * @author Curvy Protocol (https://curvy.box/)
 * @dev A mock action handler for testing purposes.
 */
contract MockActionHandler is ICSUC_ActionHandler, CSUC {
    /// @inheritdoc ICSUC_ActionHandler
    function handleAction(CSUC_Types.Action memory _action) external returns (bool _success) {
        // Always return true to simulate successful action handling
        (uint256 _balance, uint256 _nonce) =
            _unpackBalanceAndNonce(balanceAndNonce[_action.payload.token][_action.from]);

        require(_action.from != address(0), "CSUC: action from address is zero!");
        require(_action.payload.token != address(0), "CSUC: action token address is zero!");
        require(_nonce == 0, "CSUC: action nonce is not zero!");

        balanceAndNonce[_action.payload.token][_action.from] = _packBalanceAndNonce(_balance, _nonce + 1);

        (, _nonce) = _unpackBalanceAndNonce(balanceAndNonce[_action.payload.token][_action.from]);
        require(_nonce > 0, "CSUC: action nonce is greater than zero!");

        return true;
    }

    /// @inheritdoc ICSUC_ActionHandler
    function getActionId() external pure returns (uint256 _actionId) {
        return CSUC_Constants.GENERIC_CUSTOM_ACTION_ID;
    }
}
