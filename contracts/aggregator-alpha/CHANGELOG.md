# CurvyAggregatorAlpha Changelog

## V1 — Post-Audit Launch

Initial production release. The pre-launch implementation chain (V1–V6) was
flattened to a single audited V1 prior to this release; the historical
versions and their changelog entries are preserved in the repository's git
history.

### Surface

- UUPS-upgradeable proxy, owner-bound `_authorizeUpgrade` gated by
  `AUTHORITY_ROLE`.
- Single deposit entry point: `autoShield(CurvyTypes.Note)` — gated to
  registered portals via `portalFactory.portalIsRegistered(msg.sender)`.
  Deposit fee (`note.amount * curvyVault.depositFee() / 10000`) is deducted
  before the note is committed to the Merkle tree.
- ZK-verified batches: `commitDepositBatch`, `commitAggregationBatch`,
  `commitWithdrawalBatch` — each verified against the corresponding verifier
  configured via `updateConfig`.
- Withdrawals delegated to `curvyVault.withdraw(tokenId, to, amount)` (direct,
  no meta-transactions).
- Role-based access control (OZ `AccessControlUpgradeable`):
  - `AUTHORITY_ROLE` — upgrades, `updateConfig`.
  - `OPERATOR_ROLE` — operational role (`forceWithdrawal`, …).

### Production verifier set

Trees of depth 30, dimensional suffixes encode circuit shape (not contract
version):

- `CurvyInsertionVerifierAlpha_2_30` — `maxDeposits = 2`
- `CurvyAggregationVerifierAlpha_2_2_2_30` — `maxAggregations = 2`
- `CurvyWithdrawVerifierAlpha_2_2_30` — `maxWithdrawals = 2`

### Bootstrap path for existing proxies

`bootstrapAccessControl()` is `external reinitializer(2) onlyOwner` and is
called atomically via `upgradeToAndCall` during the V1 upgrade. It seeds
`AUTHORITY_ROLE` and `OPERATOR_ROLE` on `owner()`. The pre-AC
`_authorizeUpgrade(onlyOwner)` gate authorises the upgrade itself; the
`reinitializer(2)` modifier guarantees the bootstrap can only run once per
proxy.
