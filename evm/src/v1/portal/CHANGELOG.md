# Portal Changelog

Portal contracts do not use versioned files (V1, V2, etc.). Changes are tracked by commit milestones.

---

## Remove LiFi Amount Check from Factory

**Commit:** `7822eb97`

- Removed `minAmount > note.amount` check from `deployEntryBridgePortal()` — was problematic due to LiFi source swap scenarios where input amount differs from the bridged amount
- Removed `InsufficientAmountForLiFiBridging()` error from `IPortalFactory`

---

## AutoShield V2 Integration + SingleUse Inlining

**Commits:** `e3bd1192`, `371cbf11`

### Portal.sol
- Aggregator interface upgraded from `ICurvyAggregatorAlpha` to `ICurvyAggregatorAlphaV2`
- `shield()` now calls `autoShield(note)` instead of `autoShield(note, tokenAddress)` — token address parameter removed (V2 aggregator resolves it internally)
- `SingleUse` base contract removed — `_used` flag and `onlyOnce` modifier inlined directly
- On `shield()` failure (catch block), `_used` resets to `false` to allow retry if the token gets registered later

---

## Unified Bridge + LiFi Validation Moved to Factory

**Commits:** `0c50804e`, `63945e98`

The most architecturally significant refactor — LiFi data validation moved from Portal to PortalFactory.

### Portal.sol
- `entryBridge()` and `exitBridge()` replaced by single `bridge(address lifiDiamondAddress, bytes bridgeData, uint256 amount, address currency)`
- `_bridge()` internal helper removed — logic now inline in `bridge()`
- `_decodeBridgeData()` / `_decodeBridgeDataStruct()` removed — no more LiFi struct decoding in Portal
- `AGGREGATOR_CHAIN_ID` constant removed from Portal (moved to Factory)
- Errors removed from `IPortal`: `InvalidLiFiReceiver`, `InvalidLiFiDestinationChain`, `InsufficientAmountForLiFiBridging`
- `LiFiBridgeData` struct removed from `IPortal`

### PortalFactory.sol
- `AGGREGATOR_CHAIN_ID` constant added (uint256, 42161) — moved from Portal
- `deployEntryBridgePortal()`: now calls `ILiFiCalldataVerification.extractBridgeData()` on LiFi Diamond, validates receiver matches computed entry portal address and destination chain matches `AGGREGATOR_CHAIN_ID`
- `deployExitBridgePortal()`: same-chain swap uses `extractGenericSwapParameters()` to validate receiver; cross-chain uses `extractBridgeData()` to validate receiver and destination chain

### IPortalFactory.sol
- `ILiFiCalldataVerification` interface added with `LiFiBridgeData` struct (10 fields), `LiFiGenericSwapData` struct (5 fields), `extractBridgeData()` and `extractGenericSwapParameters()` functions
- Errors added: `InvalidLiFiReceiver()`, `InvalidLiFiDestinationChain()`

---

## Custom Errors, Function Renaming, Handle -> CurvyId

**Commits:** `e82f01f0`, `db03a1e7`

### Portal.sol
- Constructor validation added: ensures either entry params (ownerHash) or exit params (exitAddress + exitChainId) are set, not both — reverts with `InvalidOwnerHashOrExitBridgeData()`
- Shared `_bridge()` internal function extracted from `bridge()` and `exitBridge()` for ERC20/ETH bridge logic
- `bridge()` renamed to `entryBridge()`
- Errors renamed: `InvalidReceiver` -> `InvalidLiFiReceiver`, `InvalidDestinationChain` -> `InvalidLiFiDestinationChain`, `InsufficientAmountForBridging` -> `InsufficientAmountForLiFiBridging`, `InsufficientBalanceForBridging` -> `InsufficientBalanceForLiFiBridging`

### PortalFactory.sol
- Now explicitly implements `IPortalFactory`
- Function renames: `deployAndShield()` -> `deployShieldPortal()`, `deployAndBridge()` -> `deployEntryBridgePortal()`, `deployAndExitBridge()` -> `deployExitBridgePortal()`
- String reverts replaced with custom errors: `UnsupportedShielding()`, `DeploymentFailed()`, `UnsupportedBridging()`
- Typo `UnsuppotedShielding` fixed to `UnsupportedShielding`

---

## OnlyOwner Shield, Exit Bridge Rewrite, Error Simplification

**Commit:** `79300cac`

### Portal.sol
- `_receiverAddress` renamed to `_exitAddress`, `_chainId` (uint8) widened to `_exitChainId` (uint256)
- `_revertWithData()` helper removed — replaced by `BridgeCallFailed()` custom error
- `bridge()` logic fix: ownerHash check moved before LiFi data decoding

### PortalFactory.sol
- `deployAndShield()` gained `onlyOwner` modifier

---

## Portal Refactor — Remove Signature Verification, Add Constructor Params

**Commit:** `0f69827e`

### Portal.sol
- ECDSA/MessageHashUtils imports and signature verification removed entirely
- State variables added: `_receiverAddress` (address), `_chainId` (uint8)
- Constructor changed to `(ownerHash, receiverAddress, chainId, _recovery)` — 4 params, validates recovery not zero
- `_revertWithData(bytes)` helper added to bubble up revert strings (replaces inline assembly)
- `exitBridge()` rewritten: validates `data.receiver == _receiverAddress` and `data.destinationChainId == _chainId` using constructor values instead of signature verification
- `recover()` fixed: now properly handles native ETH (checks `address(this).balance`)

### IPortal.sol
- Error added: `InvalidRecoveryAddress()`
- `ShieldingFailed` event expanded: `(uint256 indexed ownerHash, address indexed token, uint256 amount, string reason)` — added indexing and reason string

---

## Major Portal Refactor — Remove TokenBridge, Add ExitBridge

**Commit:** `9d2efa1a`

### Portal.sol
- Imports added: `ECDSA`, `MessageHashUtils` (OpenZeppelin crypto)
- `AGGREGATOR_CHAIN_ID` constant added (uint256, 42161)
- Internal functions added: `_decodeBridgeDataStruct()`, `_decodeBridgeData()` for LiFi calldata decoding
- `bridge()` rewritten with comprehensive validation: decodes LiFi bridge data, validates receiver/destination/amount, uses custom errors, bubbles up revert data via assembly
- `tokenAddress` parameter removed from `bridge()` (derived from decoded bridge data)
- Function added: `exitBridge(address lifiDiamondAddress, uint256 amountToBridge, bytes bridgeData, bytes signature)` — ECDSA-verified exit bridging

### IPortal.sol
- Errors added: `InvalidLiFiAddress()`, `InvalidReceiver()`, `InvalidDestinationChain()`, `InsufficientAmountForBridging()`, `InsufficientBalanceForBridging()`, `InvalidSignatureOrTamperedData()`
- `LiFiBridgeData` struct added (10 fields)

---

## Deploy & Exit Bridge Added to Factory

**Commit:** `ee5d2f3d`

### PortalFactory.sol
- `getCreationCode()` now accepts 4 params: `(ownerHash, exitAddress, exitChainId, recovery)`
- `getPortalAddress()` split into `getEntryPortalAddress()` and `getExitPortalAddress()`
- Function added: `deployAndExitBridge()` — deploys exit portal via CREATE2, calls `exitBridge()`

---

## Portal Registry & IPortalFactory Interface

**Commits:** `9d214308`, `1e307448`

### PortalFactory.sol
- State variable added: `_registeredPortals` (mapping(address => bool))
- State variable added: `_aggregatorChainId` (uint256)
- Constructor changed to accept `(initialOwner, curvyVaultProxyAddress, curvyAggregatorAlphaProxyAddress, aggregatorChainId)`
- Function added: `portalIsRegistered(address) view`
- `deployAndShield()` now registers the portal in `_registeredPortals` after shielding

### IPortalFactory.sol (new file)
- Defines the full factory interface

---

## Standardize Recovery Naming

**Commit:** `b9b195f7`

- `admin` renamed to `recovery` across Portal, PortalFactory, and IPortal
- `onlyAdmin` modifier renamed to `onlyRecovery`
- `rescue()` renamed to `recover(address tokenAddress, address to)` — removed `require(_used)` check, simplified to always transfer full balance

---

## Admin Rescue Mechanism

**Commit:** `e2a7b024`

### Portal.sol
- State variable added: `admin` (address)
- Modifier added: `onlyAdmin`
- Constructor changed to accept `(ownerHash, _admin)`
- Function added: `rescue(address token, address to, uint256 amount)` — onlyAdmin, requires `_used` flag
- Event added: `ShieldingFailed(uint256 token)`
- `shield()` now wraps `curvyVault.getTokenAddress()` in try/catch; on failure emits `ShieldingFailed` and returns early

---

## SingleUse Guard

**Commit:** `50032971`

- Portal now inherits `SingleUse` (from `utils/SingleUse.sol`)
- `shield()` and `bridge()` both gain `onlyOnce` modifier — prevents replay

---

## Airlock -> Portal Rename

**Commit:** `07eef02e`

- `Airlock.sol` -> `Portal.sol`, `AirlockFactory.sol` -> `PortalFactory.sol`, `IAirlock.sol` -> `IPortal.sol`
- `getAirlockAddress()` -> `getPortalAddress()`
- CREATE2 salt changed from `"curvy-airlock-factory-salt"` to `"curvy-portal-factory-salt"`
- All revert strings updated from "Airlock:"/"AirlockFactory:" to "Portal:"/"PortalFactory:"

---

## Initial Creation (NoteDeployer -> Airlock)

**Commit:** `ead3121a`

### Portal.sol (as Airlock.sol)
- State variables: `_ownerHash` (uint256), `NATIVE_ETH` (address constant), `curvyAggregator`, `curvyVault`
- Constructor: accepts `uint256 ownerHash`
- `shield(Note, address curvyAggregatorAlphaProxyAddress, address curvyVaultProxyAddress)` — approves tokens and calls `curvyAggregator.autoShield()`
- `bridge(address lifiDiamondAddress, bytes bridgeData, Note, address tokenAddress)` — forwards call to LiFi Diamond
- No access control, string reverts

### PortalFactory.sol (as AirlockFactory.sol)
- Inherits: `Ownable`
- State variables: `_salt`, `_curvyVaultProxyAddress`, `_curvyAggregatorAlphaProxyAddress`, `_lifiDiamondAddress`
- `updateConfig(AirlockFactoryConfigurationUpdate)` — onlyOwner
- `getCreationCode(uint256 ownerHash)` — pure, returns CREATE2 bytecode
- `getAirlockAddress(uint256 ownerHash)` — view, computes CREATE2 address
- `deployAndShield(Note)` — payable, deploys via CREATE2, calls `shield()`
- `deployAndBridge(bytes bridgeData, Note, address tokenAddress)` — deploys via CREATE2, calls `bridge()`
