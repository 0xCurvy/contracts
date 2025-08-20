// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

import {CurvyAggregator_Types} from "../utils/_Types.sol";

/**
 * @title ICurvyAggregator_NoAssetTransfer
 * @author Curvy Protocol (https://curvy.box/)
 * @dev Interface for Curvy's Aggregator contract.
 */
interface ICurvyAggregator_NoAssetTransfer {
    /**
     * @notice Initializes the Aggregator contract.
     * @dev This function is called only once, during the deployment of the contract.
     *      It sets up the initial state and permissions.
     */
    function initialize() external;

    /**
     * @notice Updates the configuration of the Aggregator.
     * @dev This function allows partial update to the verifiers for insertion, aggregation, and withdrawal.
     * @param _update Configuration update structure containing the new verifiers.
     * @return _success Indication whether this call was successful.
     */
    function updateConfig(CurvyAggregator_Types.ConfigurationUpdate calldata _update)
        external
        returns (bool _success);

    /**
     * @notice Wraps either `native` or ERC20 currency into the Aggregator component.
     * @dev After this call, the newly created note is added to the pending queue,
     *      meaning it's not yet usable, and needs to be included in the note's tree root.
     *      This inclusion is performed using `.processWraps`.
     * @dev Only the CSUC (through Action Handler) can call this function.
     * @param _notes Notes that will be added to the queue.
     * @return _success Indication whether this call was successful.
     */
    function wrap(CurvyAggregator_Types.Note[] memory _notes) external returns (bool _success);

    /**
     * @notice Processes the current `wrappingQueue` and updates the note's tree.
     * @dev Only the authorized party (`operator`) can perform this call.
     *      There is an implicit option to 'reject' some requests (i.e. untrustworthy token, ...).
     *      After it was 'rejected', User can still withdraw those funds.
     * @param _data Data needed to verify correct computation, and to perform storage updates.
     * @return _success Indication whether this call was successful.
     */
    function processWraps(CurvyAggregator_Types.WrappingZKP memory _data) external returns (bool _success);

    /**
     * @notice Executes valid Users' actions (i.e. transfer, aggregate, ...).
     * @dev Only the `operator` can perform this call.
     * @param _data Data needed to verify correct computation, and to perform storage updates.
     * @return _success Indication whether this call was successful.
     */
    function operatorExecute(CurvyAggregator_Types.ActionExecutionZKP calldata _data)
        external
        returns (bool _success);

    /**
     * @notice Collects fees from the Aggregator's fee collector.
     * @dev This function allows the `feeCollector` to collect fees from the Aggregator.
     * @param _tokens Array of token addresses from which fees will be collected.
     * @param _to Address to which the collected fees will be sent.
     * @return _success Indication whether this call was successful.
     */
    function collectFees(address[] memory _tokens, address _to) external returns (bool _success);

    /**
     * @notice Executes valid Users' withdraw / unwrapping actions.
     * @dev Mostly used by the `operator`, however anyone can perform this call with correct parameters.
     * @param _data Data needed to verify correct computation, and to perform storage updates.
     * @return _success Indication whether this call was successful.
     */
    function unwrap(CurvyAggregator_Types.UnwrappingZKP calldata _data) external returns (bool _success);

    /**
     * @notice Withdraws a rejected note from the Aggregator.
     * @dev This function allows the User to withdraw their funds that were rejected during the wrapping
     * @param _noteHash The hash of the note that was rejected.
     * @return _success Indication whether this call was successful.
     */
    function withdrawRejected(bytes32 _noteHash) external returns (bool _success);

    /**
     * @notice Returns the current root of the valid notes' tree.
     * @return _root The tree's root.
     */
    function noteTree() external view returns (uint256 _root);

    /**
     * @notice Returns the current root of the used nullifiers' tree.
     * @return _root The tree's root.
     */
    function nullifierTree() external view returns (uint256 _root);

    /**
     * @notice Returns the current array of wraps that are pending to be included.
     * @param _noteHash Keccak256 hash of the note.
     * @return _note Underlying note data.
     */
    function getNoteInfo(bytes32 _noteHash)
        external
        view
        returns (CurvyAggregator_Types.NoteWithMetaData memory _note);

    /**
     * @notice Emitted when there's a 'deposit' of a token to a User's CSA.
     * @param token The token address.
     * @param amount The amount of tokens that was deposited.
     */
    event WrappingToken(address token, uint256 amount);

    /**
     * @notice Emitted when a User's CSA token balance is updated.
     * @param to The User's CSA address.
     * @param token The token address.
     * @param amount The amount of tokens that was withdrawn.
     */
    event UnwrappingToken(address to, address token, uint256 amount);
}
