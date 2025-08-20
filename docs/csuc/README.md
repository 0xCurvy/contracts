# Curvy Single User Contract (CSUC)

**Curvy Single User Contract (CSUC)** is a single-user contract that allows users to perform private **Actions** (`DEPOSIT`, `TRANSFER`, `WITHDRAW`, `SWAP`, `BRIDGE`, `AGGREGATOR_DEPOSIT`, etc.) of both [ERC20](https://eips.ethereum.org/EIPS/eip-20) and Native (i.e. Ether) tokens.

Their Actions are Gas-subsidized by the Curvy Protocol thus solving the problem of ERC20 transfers that require the User's Externally Owned Account (EOA) or Smart Contract Account to have a Native token balance.

## Different Roles

Each Account can have one of the following roles in the CSUC contract:

- **User**: A Curvy User which has at least one Curvy Stealth Address (CSA) inside the CSUC.
- **Operator**: A Curvy-owned Account that can perform actions on behalf of the protocol.
- **Fee Collector**: A Curvy-owned Account that collects fees from the CSUC contract. This is usually a protocol-controlled account.
- **Administrator**: A Curvy-owned Account that can perform administrative actions on the CSUC contract.

## Main Features & Functionality

### ERC1155 Compliant

The CSUC contract honors the [ERC1155](https://eips.ethereum.org/EIPS/eip-1155) standard, which allows users to have a single contract that can hold multiple tokens. This means that users can wrap their ERC20 and Native tokens into the CSUC contract and perform actions on them without the need for a separate contract for each token.

### Custom Core Functionalities

Besides that, three custom core functionalities of the CSUC contract were included:

- [**Wrap**](#wrapping-of-tokens): Users can wrap / deposit their tokens into the CSUC contract.

- [**User's Action Processing**](#user-actions-processing): Users can perform different actions using their wrapped tokens. The actions that can be performed are:

    - **Transfer**: Users can transfer their wrapped tokens to another user.
    - **Swap**(WIP): Users can swap their wrapped tokens for another token.
    - **Bridge**(WIP): Users can bridge their wrapped tokens to another chain.
    - **Withdraw**: Unwrapping of User's tokens through the `.operatorExecute(...)` method.
    - **Aggregator Deposit**: Users can deposit their wrapped tokens into the Curvy Aggregator contract, which allows them to perform private transfers and aggregations of multiple notes.

- [**Unwrap**](#unwrapping-of-tokens): Users can unwrap / withdraw their tokens from the CSUC contract without the Operator's involvment.

### Upgradeability

Currently, the CSUC contract is upgradeable, meaning that it can be updated to include new features. This is achieved through the use of a [UUPS Proxy Pattern](https://docs.openzeppelin.com/contracts/5.x/api/proxy), where the logic of the contract is separated from the storage. In the future, the upgradeability feature can be taken away.

## Core Functionalities

### Wrapping of Tokens

Both ERC20 and Native tokens can be wrapped into the CSUC contract.

Wrapping of Native tokens is done via the `.wrapNative(...)` method. Its function signature is:

```solidity
// File: ./src/csuc/interface/ICSUC.sol
/**
 * @notice Wraps a native token (i.e. Ether), and adds it to the User's CSA balance.
 * @dev Amount is passed as `msg.value`, and the User's CSA balance is updated accordingly.
 * @param _to The User's CSA.
 * @return _success Returns whether the call was successful.
 */
function wrapNative(address _to) external payable returns (bool _success);
```

Wrapping of ERC20 tokens is done via the `.wrapERC20(...)` method. Its function signature is:

```solidity
// File: ./src/csuc/interface/ICSUC.sol
/**
 * @notice Wraps a passed token, and adds it to the User's CSA balance.
 * @dev This function requires that the `msg.sender` has already approved the CSUC contract to spend the token.
 * @param _to The User's CSA.
 * @param _token The token address.
 *  @param _token The token address.
 * @return _success Returns whether the call was successful.
 */
function wrapERC20(address _to, address _token, uint256 _amount) external returns (bool _success);
```

_Note: The native token wrap requires a single transaction, while the ERC20 needs two (`IERC20.approve(...)` and `CSUC.wrapERC20(...)`)._

### User Actions Processing

The `.operatorExecute(...)` method is used to perform actions on behalf of the user. The method takes a list of actions that the multiple Users wants to perform, and the Operator executes them in a single transaction.

Each `Action` is uniquely defined as:

```solidity
// File: ./src/csuc/utils/_Types.sol
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
```

Where the `ActionPayload` structure is laid out as:

```solidity
// File: ./src/csuc/utils/_Types.sol
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
```

and the `signature_<r|s|v>` fields are computed using the User's CSA's private key against a `keccak256` hash:

```solidity
keccak256(abi.encode(block.chainid, _payload, _nonce));
```

where:

- `block.chainid` is the chain ID of the network where the action is being executed
- `_payload` is the `ActionPayload`
- `_nonce` is a nonce that is incremented after each execution of a User's action. The nonce is used to prevent replay attacks and ensure that each action can only be executed once.

_Note: In order to lower the execution cost due to storage write, each `_nonce` is packed along with the `balance` of the User's CSA in a single storage slot. This means that each `_payload.token` has its own nonce._

#### User Action Execution

Each User's individual `Action` goes through two stages:

- **Validation** which determines whether the `Action` can be executed
- **Execution** which performs state-updates based on a valid `Action`'s data

#### Validation of User's Actions

Each `Action` is validated before execution. The validation checks that:

- The `from` address is the User's CSA.
- The `signature_v`, `signature_r`, and `signature_s` fields are valid and correspond to the User's CSA's private key.
- The `limit` is greater than or equal to the current block number.
- The `totalFee` was correctly calculated based on action type.
- The `balance` is greater than or equal to the `totalFee + amount`.
- The `actionId` is a valid action ID that is supported by the CSUC contract

If any of these checks fail, the action is simply not executed. This allows for other valid actions to be executed in the same transaction, while the invalid ones are skipped.

#### Execution of User's Actions

There are different types of actions that a User can perform. Each type, has its own `handler` associated with the neccessary logic.

Handlers for core actions (`DEPOSIT`, `TRANSFER` and `WITHDRAW`) is contained directly in the contract itself.

##### Adding new Action Types

New types of actions (i.e. `SWAP`, `BRIDGE`, `AGGREGATOR_DEPOSIT`, etc.) can be supported after the initial CSUC deployment. Handlers for these actions are separate contracts to whom the main contract issues an `.delegatecall` thus enabling state updates (mainly balances and nonces) on it.

_Note: In order to improve both security and transparency, this addition of new actions, is time-delayed after the Curvy Administrator's transaction that updated the configuration via the `.updateConfig(...)` call._

Each handler must honor the `ICSUC_ActionHandler` interface:

```solidity
// File: ./src/csuc/interface/ICSUC_ActionHandler.sol
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
```

### Unwrapping of Tokens

Unwrapping of Native tokens is done via the `.unwrapNative(...)` method. Its function signature is:

```solidity
// File: ./src/csuc/interface/ICSUC.sol
/**
 * @notice Unwraps (Withdraws) a passed token from CSA's balance to the desired destination.
 * @param _action The action containing all of the necessary info.
 * @return _success Returns whether the call was successful.
 */
function unwrap(CSUC_Types.Action memory _action) external returns (bool _success);
```

_Note: This method allows anyone to execute a User's withdrawal action if the signatures are valid, meaning that the User can delegate the withdrawal to circumvent the need for them to have a Native token balance._

## Terminology Glossary

- **CSA**: Curvy Protocol-generated Stealth Address. In the current form this is a Externally Owned Account (EOA) meaning that it is controlled by a private key.
- **CSUC**: Curvy Single User Contract. A contract that allows users to perform private actions with their wrapped tokens.
- **Action**: A single action that can be performed by the User.

## Deployments

### Ethereum Sepolia

| Contract | Address                                      | Block Explorer                                                                                       |
| -------- | -------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| CSUC     | `0x11EfE6DffF2f3416d9426384674B855C28953d6a` | [Etherscan Sepolia](https://sepolia.etherscan.io/address/0x11EfE6DffF2f3416d9426384674B855C28953d6a) |

### Ethereum Mainnet

_Scheduled for Q3 2025_.
