// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

/* * @title CSUC_Types
 * @author Curvy Protocol (https://curvy.box/)
 * @dev Types used in the CSUC components.
 */
library CSUC_Types {
    /**
     * @notice Information about the on-chain configuration updates.
     * @dev This structure supports partial config. field updates.
     * @param newOperator The new operator address.
     * @param newFeeCollector The new fee collector address.
     * @param newAggregator The new aggregator address.
     * @param actionHandlingInfoUpdate An array of action handling information updates.
     */
    struct ConfigUpdate {
        address newOperator;
        address newFeeCollector;
        address newAggregator;
        ActionHandlingInfoUpdate[] actionHandlingInfoUpdate;
    }

    /**
     * @notice Information about the action handling updates.
     * @param actionId The unique ID of an action.
     * @param info The action handling information.
     */
    struct ActionHandlingInfoUpdate {
        uint256 actionId; // unique ID of an action
        ActionHandlingInfo info;
    }

    /**
     * @notice Information about the action handling.
     * @param mandatoryFeePoints The mandatory fee points for this action.
     * @param handler The contract handler for this action.
     */
    struct ActionHandlingInfo {
        uint16 mandatoryFeePoints;
        address handler;
    }

    /**
     * @notice Information about the action payload.
     * @dev This structure is used to pass the action parameters to the action handler.
     * @param token The token to be used for the action.
     * @param actionId The ID of the action to be performed.
     * @param amount The amount to be affected (not including totalFee).
     * @param totalFee The total fee to be taken from the `from` balance and added to the `feeCollector`.
     * @param limit The block number until this action can be executed.
     * @param parameters The encoded parameters for the action.
     */
    struct ActionPayload {
        address token;
        uint256 actionId;
        uint256 amount;
        uint256 totalFee;
        uint256 limit;
        bytes parameters;
    }

    /**
     * @notice Information about the action.
     * @dev This structure is used to pass the action parameters to the action handler.
     * @param from The address of the User's CSA that owns the funds inside the contract.
     * @param signature_v The v value of the signature.
     * @param signature_r The r value of the signature.
     * @param signature_s The s value of the signature.
     * @param payload The action payload containing all necessary parameters for the action execution.
     */
    struct Action {
        address from;
        uint8 signature_v;
        bytes32 signature_r;
        bytes32 signature_s;
        ActionPayload payload;
    }

    /**
     * @notice Information about the User's CSA.
     * @param owner The address of the User's CSA owner.
     * @param token The token address used for the User's CSA.
     * @param balance The User's CSA balance.
     * @param nonce The User's CSA nonce.
     */
    struct CSAInfo {
        address owner;
        address token;
        uint256 balance;
        uint256 nonce;
    }
}
