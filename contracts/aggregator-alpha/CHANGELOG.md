# CurvyAggregatorAlpha Changelog

## V6

### Fee Deduction in AutoShield

- `autoShield` now calculates a deposit fee: `note.amount * curvyVault.depositFee() / 10000`
- The note committed to the Merkle tree uses `note.amount - feeAmount` instead of `note.amount`, so the committed note reflects the post-fee amount
- Vault interface upgraded from `ICurvyVaultV2` to `ICurvyVaultV3`
- `curvyVault` state variable type changed from `ICurvyVaultV2` to `ICurvyVaultV3`

---

## V5

### Meta-Transaction Removal & Circuit Layout Change

#### Removed
- **`depositNote` function removed** — the meta-transaction-based deposit path (with EIP-712 signatures) is gone entirely

#### Changed: `autoShield`
- `tokenAddress` parameter removed from signature — now resolved internally via `curvyVault.getTokenAddress(note.token)`
- Access control changed from `require(...)` string to custom error `PortalNotRegistered()`
- Vault deposit call changed from 4 args `(tokenAddress, address(this), note.amount, 0)` to 3 args `(tokenAddress, address(this), note.amount)` (gas sponsorship parameter removed), matching `ICurvyVaultV2`

#### Changed: `commitDepositBatch`
- Return type `bool success` removed (now returns nothing)
- All `require(...)` replaced with custom errors: `NoteNotScheduledForDeposit()`, `InvalidNotesRoot()`, `InvalidProof()`

#### Changed: `commitAggregationBatch`
- Return type `bool` removed
- All `require(...)` replaced with custom errors: `CurrentNoteTreeRootMismatch()`, `CurrentNullifierTreeRootMismatch()`, `InvalidProof()`

#### Changed: `commitWithdrawalBatch`
- `publicInputs` array size changed from `uint256[10]` to `uint256[9]` (new circuit layout)
- Public input index offsets shifted: old notes tree root moved from `[2]` to `[1]`, old nullifiers tree root from `[3]` to `[2]`, withdrawal amounts from `[4+i]` to `[3+i]`, destinations from `[4+maxWithdrawals+i]` to `[3+maxWithdrawals+i]`
- Withdrawal mechanism changed from `curvyVault.transfer(MetaTransaction(...))` to `curvyVault.withdraw(tokenId, destinationAddress, amount)` — direct withdraw instead of meta-transaction pattern
- Fee collection step removed entirely
- Return type `bool` removed
- All `require(...)` replaced with custom errors

#### Changed: View Functions
- `getNullifierTreeRoot()` renamed to `getNullifiersTreeRoot()` (added "s")

#### Interface & Imports
- Interface changed from `ICurvyAggregatorAlpha` to `ICurvyAggregatorAlphaV2` (removes `tokenAddress` param from `autoShield`)
- Vault interface changed from `ICurvyVault` to `ICurvyVaultV2`
- `withdrawVerifier` type changed from `ICurvyWithdrawVerifier` to `ICurvyWithdrawVerifierV3`
- Added `ICurvyWithdrawVerifierV3` import

#### Comments
- NatSpec comment added to `reset` documenting it as emergency-only
- Improved comments on `maxAggregations`, `maxWithdrawals`, `_pendingIdsQueue`

---

## V4

### Portal Factory Integration

#### Added
- `IPortalFactory public portalFactory` state variable
- Portal registration check in `autoShield`: `require(portalFactory.portalIsRegistered(msg.sender), ...)` — only registered portals can call `autoShield`

#### Changed: `initialize`
- `curvyVaultProxyAddress` parameter removed — vault must now be configured post-deployment via `updateConfig`
- Default max values (`maxDeposits`, `maxWithdrawals`, `maxAggregations`) no longer set during initialization

#### Changed: `updateConfig`
- Parameter type changed from `AggregatorConfigurationUpdate` to `AggregatorConfigurationUpdateV2`
- Added `portalFactory` configuration support

---

## V3

### AutoShield & SafeERC20

#### Added
- `autoShield(CurvyTypes.Note memory note, address tokenAddress) external payable` — new function for portal-based deposits. Handles ERC-20 via `safeTransferFrom` + `forceApprove`, then calls `curvyVault.deposit`. Computes `noteId` via `PoseidonT4.hash`, adds to `_pendingIdsQueue`, emits `DepositedNote`. No access control in this version.
- `NATIVE_ETH` constant (`0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE`) — sentinel address for native ETH handling
- `using SafeERC20 for IERC20` directive

#### Changed: Inheritance
- Added `ICurvyAggregatorAlpha` interface to inheritance chain

#### New Imports
- `ICurvyAggregatorAlpha` from `./ICurvyAggregatorAlpha.sol`
- `SafeERC20` and `IERC20` from OpenZeppelin

---

## V2

### Withdrawal MetaTransaction Type Fix

#### Changed: `commitWithdrawalBatch`
- Per-user withdrawal transfers changed from `CurvyTypes.MetaTransactionType.Withdraw` to `CurvyTypes.MetaTransactionType.Transfer`

---

## V1

Initial release. Core aggregator contract with:
- `initialize`, `_authorizeUpgrade`, `updateConfig`, `reset`
- `depositNote` — meta-transaction-based note deposit with EIP-712 signature verification
- `commitDepositBatch` — batch deposit commitment with ZK insertion proof verification
- `commitAggregationBatch` — batch aggregation with ZK proof verification
- `commitWithdrawalBatch` — batch withdrawal with ZK proof verification and vault transfers
- View functions: `getNotesTreeRoot`, `getNullifierTreeRoot`, `getConfig`, `getPendingNoteIds`
