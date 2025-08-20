// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.30;

/* * @title CSUC_Constants
 * @author Curvy Protocol (https://curvy.box/)
 * @dev Constants used in the CSUC components.
 */
library CSUC_Constants {
    /// The CSUC (ERC1155) contract URI.
    string public constant CSUC_URI = "https://curvy.box/csuc";

    // :::CORE actions:::

    /// Operator-specific action that is used to 'clear' the current token & amount used for fee calculation.
    uint256 public constant CLEAR_ACTION_ID = uint256(keccak256(abi.encode("CSUC_CLEAR_ACTION_ID")));

    /// Action ID for the `wrap`/deposit action.
    uint256 public constant DEPOSIT_ACTION_ID = uint256(keccak256(abi.encode("CSUC_DEPOSIT_ACTION_ID")));

    /// Action ID used for the transfer action.
    uint256 public constant TRANSFER_ACTION_ID = uint256(keccak256(abi.encode("CSUC_TRANSFER_ACTION_ID")));

    /// Action ID for the `unwrap`/withdraw action.
    uint256 public constant WITHDRAWAL_ACTION_ID = uint256(keccak256(abi.encode("CSUC_WITHDRAWAL_ACTION_ID")));

    /// Mocked address for the core action handlers.
    address public constant CORE_ACTION_HANDLER =
        address(uint160(uint256(keccak256(abi.encode("CSUC_CORE_ACTION_HANDLER")))));

    // :::Custom actions:::

    /// Action ID for the generic custom action.
    uint256 public constant GENERIC_CUSTOM_ACTION_ID = uint256(keccak256(abi.encode("CSUC_GENERIC_CUSTOM_ACTION_ID")));

    /// Used in the `mandatoryFee` calculation.
    /// The fee is calculated as:
    //       `mandatoryFee = (mandatoryFeePoints * _amount) / FEE_PRECISION`;
    //       where `_amount` is the amount of tokens being transferred.
    //       For 0.2% fee, `mandatoryFeePoints` should be set to 2 * (FEE_PRECISION / 1_000).
    uint256 public constant FEE_PRECISION = 10 ** 10;

    /// Native token ID/'Address' - used to comply with ERC20 handlers
    address public constant NATIVE_TOKEN = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// The maximum supported number of bits when packing User's CSA balance.
    uint256 public constant BITS_FOR_BALANCE = 200;

    /// The maximum supported number of bits when packing User's CSA nonce.
    uint256 public constant BITS_FOR_NONCE = 55;

    /// The maximum allowed balance.
    uint256 public constant MAX_BALANCE = (1 << BITS_FOR_BALANCE) - 1;

    /// The mask to extract the balance from the packed User's CSA data.
    uint256 public constant MASK_BALANCE = (1 << BITS_FOR_BALANCE) - 1;

    /// The maximum allowed nonce.
    uint256 public constant MAX_NONCE = (1 << (BITS_FOR_NONCE - 1)) - 1;

    /// The mask to extract the nonce from the packed User's CSA data.
    uint256 public constant MASK_NONCE = (1 << BITS_FOR_NONCE) - 1;

    /// Notice: The time period after which the action becomes active.
    /// Explanation: This is used to prevent the action from being executed immediately after it is created.
    ///       If the execution of a not-yet-active action is attempted, it will be passed over.
    uint256 public constant ACTION_BECOMES_ACTIVE_AFTER_BLOCKS = 1;
}
