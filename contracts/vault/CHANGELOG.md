# CurvyVault Changelog

## V6

### Interface Upgrade Only

- Interface changed from `ICurvyVaultV2` to `ICurvyVaultV3`
- `ICurvyVaultV3` formally declares `depositFee()` and `withdrawalFee()` view functions in the interface (previously only available as auto-generated public state variable getters)
- No implementation changes

---

## V5

### Meta-Transaction System Removal & API Simplification

This is the largest architectural change in the contract's history — the entire EIP-712 meta-transaction/signature system was removed in favor of a direct deposit/withdraw API.

#### Removed Functions
- `_validateSignature` — EIP-712 signature validation
- `_transfer` — internal transfer logic
- `_withdraw` — internal withdraw logic
- `transfer(MetaTransaction)` — direct meta-transaction transfer
- `transfer(MetaTransaction, bytes signature)` — relayed meta-transaction transfer
- `withdraw(MetaTransaction)` — direct meta-transaction withdraw
- `withdraw(MetaTransaction, bytes signature)` — relayed meta-transaction withdraw
- `receive() external payable` — vault no longer accepts direct ETH transfers
- `balanceOfBatch` — batch balance query
- `getNonce` — nonce query (meta-transactions removed)

#### Added Functions
- `deregisterToken(address tokenAddress) external onlyOwner` — removes a token from both ID mappings, emits `TokenDeregistered`
- `collectFees(uint256 tokenId) external onlyOwner` — withdraws accumulated fee balance for a token
- `withdraw(uint256 tokenId, address to, uint256 amount) external` — new simplified withdraw, restricted to `_curvyAggregator` or `owner()`, applies withdrawal fee

#### Changed: `deposit`
- `gasSponsorshipAmount` parameter removed (4 args → 3 args)
- Gas sponsorship deduction logic removed
- Token ID lookup and validation now happens **before** `safeTransferFrom` (prevents wasted gas on unregistered tokens)
- Error handling changed to custom errors: `NotCurvyAggregator()`, `ERC20TransferFailed()`, `ETHTransferFailed()`

#### Changed: `setFeeAmount`
- Signature changed from `(MetaTransactionType, uint96)` to `(FeeUpdate calldata)`
- If/else chain replaced by direct struct field assignment
- Event changed from per-type `FeeChange` to `FeeChange(FeeUpdate)`

#### Changed: `registerToken`
- `require(...)` replaced with `if (...) revert TokenAlreadyRegistered()`

#### Changed: View Functions
- `getTokenAddress` and `getTokenId` — require strings replaced with `revert TokenNotRegistered()`

#### Deprecated (kept for storage layout compatibility)
- `CURVY_META_TRANSACTION_TYPE_HASH` constant — no longer referenced
- `transferFee` state variable — no longer used

#### Events
- Removed: `Transfer`, `NonceChange`
- Added: `Deposit(address indexed tokenAddress, address indexed to, uint256 amount)`, `Withdraw(address indexed tokenAddress, address indexed to, uint256 amount)`, `TokenDeregistered(address tokenAddress, uint256 tokenId)`

#### Errors
- Removed: `InvalidSender`, `InvalidTransactionType`, `InvalidGasSponsorship`, `InsufficientBalance`, `InsufficientAmountForGas`
- Added: `NotCurvyAggregator`, `TokenAlreadyRegistered`, `InvalidDestinationAddress`, `ERC20TransferFailed`, `WithdrawalFeeNotSet`, `NotCurvyAggregatorOrOwner`

#### EIP-712
- Version string changed from `"2.0"` back to `"1.0"`

---

## V4

### Gas Fee Source Change in Transfers

#### Changed: `_transfer`
- Gas fee deduction moved from `_balances[metaTransaction.to]` (recipient) to `_balances[metaTransaction.from]` (sender) — the sender now pays the gas fee instead of the recipient

---

## V3

### Aggregator-Gated Deposits

#### Added
- `address private _curvyAggregator` state variable
- `setCurvyAggregatorAddress(address) external onlyOwner` — sets the aggregator address, emits `CurvyAggregatorAddressChange`

#### Changed: `deposit`
- Added access control: `require(msg.sender == _curvyAggregator, ...)` — only the CurvyAggregator contract can call `deposit`

---

## V2

### Custom Errors & Withdrawal Fee Bugfix

#### Changed: Error Handling
- Multiple `require(...)` with string messages replaced by custom error reverts across `_transfer`, `deposit`, `transfer`, and `withdraw` functions: `InvalidRecipient()`, `InvalidTransactionType()`, `InvalidSender()`, `InvalidGasSponsorship()`

#### Changed: `_withdraw` — Critical Bugfix
- V1 deducted gas fee and withdrawal fee from `_balances` separately but still transferred the full pre-fee `metaTransaction.amount` to the recipient
- V2 introduces `amountAfterFees` local variable — fees are subtracted from this amount, and only `amountAfterFees` is transferred to the recipient

#### Changed: EIP-712
- Version string changed from `"1.0"` to `"2.0"`

---

## V1

Initial release. EIP-712 meta-transaction vault with:
- `initialize`, `_authorizeUpgrade`
- Token registration: `registerToken`
- Deposits: `deposit(address tokenAddress, address to, uint256 amount, uint256 gasSponsorshipAmount)`
- Meta-transaction transfers: `transfer(MetaTransaction)`, `transfer(MetaTransaction, bytes signature)`
- Meta-transaction withdrawals: `withdraw(MetaTransaction)`, `withdraw(MetaTransaction, bytes signature)`
- Fee management: `setFeeAmount`, `setCurvyAggregatorAddress`
- View functions: `balanceOf`, `balanceOfBatch`, `getNonce`, `getTokenAddress`, `getTokenId`
- `receive() external payable` for accepting direct ETH
