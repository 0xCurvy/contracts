# CurvyVault Changelog

## V1 — Post-Audit Launch

Initial production release. The pre-launch implementation chain (V1–V6) was
flattened to a single audited V1 prior to this release; the historical
versions and their changelog entries are preserved in the repository's git
history.

### Surface

- UUPS-upgradeable proxy, owner-bound `_authorizeUpgrade` gated by
  `AUTHORITY_ROLE`.
- Direct deposit/withdraw API (no meta-transactions, no relayed signatures).
- Native ETH (`0xEee…EEeE`) is registered as token id `1` at `initialize`;
  ERC-20s registered via `registerToken(address)`.
- Fee model: `depositFee` (default 10 bps) and `withdrawalFee` (default 20 bps),
  capped at `MAX_FEE = 1000` (10%). Fees accumulate at `_feeCollectorAddress`
  (rotated via `setFeeCollectorAddress`) and are claimed via
  `collectFees(tokenId)`.
- Role-based access control (OZ `AccessControlUpgradeable`):
  - `AUTHORITY_ROLE` — upgrades, `registerToken`, `deregisterToken`,
    `setCurvyAggregatorAddress`, `setFeeAmount`, `setFeeCollectorAddress`.
  - `OPERATOR_ROLE` — operational calls (e.g. `collectFees`).
  - `_setRoleAdmin(OPERATOR_ROLE, AUTHORITY_ROLE)` and
    `_setRoleAdmin(AUTHORITY_ROLE, AUTHORITY_ROLE)`.

### Bootstrap path for existing proxies

`bootstrapAccessControl()` is `external reinitializer(2) onlyOwner` and is
called atomically via `upgradeToAndCall` during the V1 upgrade. It seeds
`AUTHORITY_ROLE` and `OPERATOR_ROLE` on `owner()` and sets
`_feeCollectorAddress = owner()`. The pre-AC `_authorizeUpgrade(onlyOwner)`
gate authorises the upgrade itself; the `reinitializer(2)` modifier guarantees
the bootstrap can only run once per proxy.

### Storage layout notes

- `__deprecated_transaction_fee` (uint96) — formerly `transferFee`; kept in
  storage layout for backwards-compatible upgrades from pre-V1 proxies.
