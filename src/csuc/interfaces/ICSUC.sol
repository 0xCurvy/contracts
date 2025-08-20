// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {CSUC_Types} from "../utils/_Types.sol";
import {CSUC_Constants} from "../utils/_Constants.sol";

/**
 * @title ICSUC
 * @author Curvy Protocol (https://curvy.box/)
 * @dev Interface for CSUC main contract.
 */
interface ICSUC {
    /**
     * @notice Updates the protocol's on-chain configuration.
     * @dev This function allows the protocol's `owner` to update the existing action handling fields,
     *      as well as the `fee collector` / `operator` address, and to add new actions to the CSUC.
     * @return _success Returns whether the call was successful.
     */
    function updateConfig(CSUC_Types.ConfigUpdate memory _update) external returns (bool _success);

    /**
     * @notice Executes a bundle of User actions.
     * @dev This function allows the `operator` to execute multiple actions in a single transaction.
     *      The actions must be valid. Invalid actions will passed over.
     * @param _actions An array of User actions to be executed.
     * @return _actionsExecuted Returns the number of successfully executed actions.
     */
    function operatorExecute(CSUC_Types.Action[] memory _actions) external returns (uint256 _actionsExecuted);

    /**
     * @notice Executes arbitarily (authorized) callback for the Action Handler.
     * @param _actions An array of User actions to be executed.
     * @return _actionsExecuted Returns the number of successfully executed actions.
     */
    function actionHandlerCallback(CSUC_Types.Action[] memory _actions) external returns (uint256 _actionsExecuted);

    /**
     * @notice Returns the User's CSA token balance;
     * @param _owner The User's CSA.
     * @param _token The token address.
     * @return _balance Returns the User's CSA token balance.
     */
    function balanceOf(address _owner, address _token) external view returns (uint256 _balance);

    /**
     * @notice Returns the User's CSA token balance;
     * @param _owner The User's CSA.
     * @param _token The token address.
     * @return _nonce Returns the User's CSA token balance.
     */
    function nonceOf(address _owner, address _token) external view returns (uint256 _nonce);

    /**
     * @notice Wraps a passed token, and adds it to the User's CSA balance.
     * @dev This function allows passing a native token as `msg.value` that will be also added to the User's CSA balance.
     * @param _to The User's CSA.
     * @param _token The token address.
     *  @param _token The token address.
     * @return _success Returns whether the call was successful.
     */
    function wrap(address _to, address _token, uint256 _amount) external payable returns (bool _success);

    /**
     * @notice Wraps a native token (i.e. Ether), and adds it to the User's CSA balance.
     * @dev Amount is passed as `msg.value`, and the User's CSA balance is updated accordingly.
     * @param _to The User's CSA.
     * @return _success Returns whether the call was successful.
     */
    function wrapNative(address _to) external payable returns (bool _success);

    /**
     * @notice Wraps a passed token, and adds it to the User's CSA balance.
     * @dev This function requires that the `msg.sender` has already approved the CSUC contract to spend the token.
     * @param _to The User's CSA.
     * @param _token The token address.
     *  @param _token The token address.
     * @return _success Returns whether the call was successful.
     */
    function wrapERC20(address _to, address _token, uint256 _amount) external returns (bool _success);

    /**
     * @notice Unwraps (Withdraws) a passed token from CSA's balance to the desired destination.
     * @param _action The action containing all of the necessary info.
     * @return _success Returns whether the call was successful.
     */
    function unwrap(CSUC_Types.Action memory _action) external returns (bool _success);

    /**
     * @notice Returns the mandatory fee for a given action.
     * @dev The fee is calculated based on the action ID and the amount of tokens involved.
     * @param _actionId The ID of the action for which the fee is being calculated.
     * @param _amount The amount of tokens involved in the action.
     * @return _mandatoryFee Returns the mandatory fee for the action.
     */
    function getMandatoryFee(uint256 _actionId, uint256 _amount) external view returns (uint256 _mandatoryFee);

    /**
     * @notice Returns the action handling info for a given action ID.
     * @dev This function provides details about how a specific action is handled, including the handler address and any additional parameters.
     * @param _actionId The ID of the action for which the handling info is requested.
     * @return _actionHandlingInfo Returns the action handling info.
     */
    function getActionHandlingInfo(uint256 _actionId)
        external
        view
        returns (CSUC_Types.ActionHandlingInfo memory _actionHandlingInfo);

    /**
     * @notice Returns the indication whether a specific action is active.
     * @dev After adding a new custom action, there is a time delay before it becomes active, and can be invoked.
     * @return _success Returns whether the call was successful.
     */
    function actionIsActive(uint256 _actionId) external view returns (bool _success);

    /**
     * @notice Returns the User's CSA information for a given owner and token.
     * @param _owners The User's CSA owner addresses.
     * @param _tokens The token address used for the User's CSAs.
     * @return _csaInfos Returns the User's CSA information.
     */
    function batchCSAInfo(address[] memory _owners, address[] memory _tokens)
        external
        view
        returns (CSUC_Types.CSAInfo[] memory _csaInfos);

    /**
     * @notice Emitted when a on-chain configuration is updated.
     * @param update The passed configuration update object.
     */
    event ConfigUpdated(CSUC_Types.ConfigUpdate update);

    /**
     * @notice Emitted when any User's CSA action is executed.
     * @param action The passed action object which was executed.
     */
    event ActionExecuted(CSUC_Types.Action action);

    /**
     * @notice Emitted when there's a 'deposit' of a token to a User's CSA.
     * @param to The User's CSA address.
     * @param token The token address.
     * @param amount The amount of tokens that was deposited.
     */
    event WrappingToken(address to, address token, uint256 amount);

    /**
     * @notice Emitted when a User's CSA token balance is updated.
     * @param to The User's CSA address.
     * @param token The token address.
     * @param amount The amount of tokens that was withdrawn.
     */
    event UnwrappingToken(address to, address token, uint256 amount);
}
