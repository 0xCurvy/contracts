# Curvy Aggregator Contract

**Curvy Aggregator** contract allows users to perform private **Actions** (`DEPOSIT`, `AGGREGATE`, `WITHDRAW`) of both [ERC20](https://eips.ethereum.org/EIPS/eip-20) and Native (i.e. Ether) tokens.

The core `AGGREGATE` functionality allows users to aggregate their notes into a single note, which can then be used for future actions. This is particularly useful for reducing the number of notes a user has to manage, thus improving privacy and efficiency.

Their Actions are Gas-subsidized by the Curvy Protocol thus solving the problem of ERC20 transfers that require the User's Externally Owned Account (EOA) or Smart Contract Account to have a Native token balance.

## Different Roles

Each Account can have one of the following roles in the Aggregator contract:

- **User**: A Curvy User that can deposit, withdraw, and aggregate notes.
- **Operator**: A Curvy-owned Account that can perform actions on behalf of the protocol.
- **Fee Collector**: A Curvy-owned Account that collects fees from the Aggregator contract. This is usually a protocol-controlled account.
- **Administrator**: A Curvy-owned Account that can perform administrative actions on the Aggregator contract.

## Main Functionality

### Upgradeability

Currently, the Aggregator contract is upgradeable, meaning that it can be updated to include new features. This is achieved through the use of a [UUPS Proxy Pattern](https://docs.openzeppelin.com/contracts/5.x/api/proxy), where the logic of the contract is separated from the storage. In the future, the upgradeability feature can be taken away.

### Deposit

At this stage, only deposits through CSUC contract are supported. The `deposit` function allows users to deposit notes into the Aggregator contract. The deposited notes are temporarily stored in a 'queue' until they are picked up by the Curvy Operator, who will then process them and insert them into the notes tree.

#### Wrapping of Tokens

Both ERC20 and Native tokens can be wrapped into the Aggregator contract.

Wrapping of Native tokens is done via the `.wrapNative(...)` method. Its function signature is:

```solidity
// File: ./src/aggregator/interface/ICurvyAggregator.sol
/**
  * @notice Wraps `native` currency into the Aggregator component.
  * @dev After this call, the newly created note is added to the pending queue,
  *      meaning it's not yet usable, and needs to be included in the note's tree root.
  *      This inclusion is performed using `.processWraps`.
  * @param _notes Notes that will be added to the queue.
  * @return _success Indication whether this call was successful.
  */
function wrapNative(CurvyAggregator_Types.Note[] memory _notes) external payable returns (bool _success);
```

Wrapping of ERC20 tokens is done via the `.wrapERC20(...)` method. Its function signature is:

```solidity
// File: ./src/aggregator/interface/ICurvyAggregator.sol
/**
  * @notice Wraps a ERC20 token currency into the Aggregator component.
  * @dev After this call, the newly created note is added to the pending queue,
  *      meaning it's not yet usable, and needs to be included in the note's tree root.
  *      This inclusion is performed using `.processWraps`.
  * @param _notes Notes that will be added to the queue.
  * @return _success Indication whether this call was successful.
  */
function wrapERC20(CurvyAggregator_Types.Note[] memory _notes) external returns (bool _success);
```

_Note: The native token wrap requires a single transaction, while the ERC20 needs two (`IERC20.approve(...)` and `CSUC.wrapERC20(...)`)._

### ZK Proof Verification

Each of the Actions (`DEPOSIT`, `AGGREGATE`, `WITHDRAW`) requires a ZK proof to be verified. The proof is generated off-chain and submitted to the contract for verification.

The main contract uses a set of auto-generated verifiers to verify the proofs:

- [CurvyInsertionVerifier](./src/aggregator/verifiers/v0/CurvyInsertionVerifier.sol) which verifies the `INSERTION` action.
- [CurvyAggregationVerifier](./src/aggregator/verifiers/v0/CurvyAggregationVerifier.sol) which verifies the `AGGREGATION` action.
- [CurvyWithdrawVerifier](./src/aggregator/verifiers/v0/CurvyWithdrawVerifier.sol) which verifies the `WITHDRAW` action.

The current versions of these verifiers were taken from the [0xCurvy/curvy-keys](https://github.com/0xCurvy/curvy-keys) repository.

Each of these verifiers has a distinct `.verifyProof(...)` method that takes the proof parameters and public inputs as arguments.

The full, low-level signature of it is as follows:

```solidity
function verifyProof(
    uint256[2] memory a,
    uint256[2][2] memory b,
    uint256[2] memory c,
    uint256[<ActionDependent>] memory input
) external view returns (bool success);
```

The first three parameters (`a`, `b`, `c`) are the proof parameters, while the last parameter (`input`) is a flat array of public inputs that depend on the specific action being verified.

The order of the public inputs in the `input` array is crucial, as it must match the order expected by the verifier.

For the current version of the verifiers, the public inputs are structured as follows:

```js
CurvyInsertionVerifier.input = [
  ...notes[maxNotes * 3],   // The notes to be inserted
  oldNotesRoot,             // The root of the old notes tree
  newNotesRoot              // The root of the new notes tree
]

// Currently, maxNotes = 50
// where the notes are flat-encoded (each note has 3 fields) as:
// [ownerHash0, amount0, token0, ownerHash1, amount1, token1, ...]

CurvyAggregationVerifier.input = [
  oldNullifiersRoot,        // The root of the old nullifiers tree
  newNullifiersRoot,        // The root of the new nullifiers tree
  oldNotesRoot,             // The root of the old notes tree
  newNotesRoot,             // The root of the new notes tree
  ...ephemeralKeys,         // The ephemeral keys used for aggregation
  nullifiersHash            // The hash of all the nullifiers
  outputNoteIds             // The IDs of the output notes
]

CurvyWithdrawVerifier.input : [
  notesTreeRoot;            // The current root of the notes tree
  oldNullifiersRoot;        // The root of the old nullifiers tree
  destinationAddress;       // The chain address of the recipient
  withdrawFlag;             // CSUC withdraw flag
  withdrawAmount;           // The amount to be withdrawn
  ...nullifiers             // The nullifiers for the withdrawal
  newNullifiersRoot;        // The root of the new nullifiers tree
  token;                    // The token being withdrawn
  outputsHash;              // The hash of the outputs
  feeAmount;                // The fee amount taken
]
```

### General Withdraw

Users can withdraw their notes from the Aggregator contract using the `.unwrap(...)` function. This function requires a valid ZK proof to be provided, which is verified by the `CurvyWithdrawVerifier`. Normally, the User wouldn't need call this function, as it would be handled by the Curvy Operator. Still, this function is permissionless as to not block any User from withdrawing their funds

### Withdraw to CSUC

The Aggregator contract supports a special type of withdrawal called **CSUC Withdrawal**. This allows users to withdraw their notes to the CSUC component, from which they can do additional set of actions.

To do this, the `withdrawFlag` in the `CurvyWithdrawVerifier.input` must be set to `1`, and the `destinationAddress` will be the address of the recipient on the CSUC.

## Terminology Glossary

**Curvy Single User Contract (CSUC)**: Separate component used by Curvy Protocol to manage User's Stealth Addresses (see [../csuc/README.md](../csuc/README.md) for more detailed information).

## Deployment Procedure

First deploy the ZK verifiers:

```bash
yarn run deploy:zk-verifiers
```

Then, update the [CurvyAggregator_Deploy.sol](../../script/CurvyAggregator_Deploy.s.sol) with new addresses, and run:

```bash
yarn run deploy:aggregator
```
