# Curvy Portal Solana — EVM Developer Guide

> This report explains the Solana smart contract in terms familiar to EVM developers.
> No Rust or Solana knowledge required.

---

## What Is This?

This is a **bridge contract** deployed on Solana that moves assets (SOL and USDC) from Solana to Arbitrum. Think of it as a smart contract that:

1. Creates **stealth deposit addresses** (like CREATE2 deterministic addresses on EVM)
2. Accepts user deposits into those addresses
3. Bridges the funds to Arbitrum through an explicitly supported provider adapter
   (**Relay**, **Eco**, or the separate direct **Across** integration)
4. Has a **recovery mechanism** so funds are never stuck

The backend (operator) orchestrates everything. Users just send funds to a pre-computed address.

---

## Key Conceptual Differences from EVM

Before diving in, here are the Solana concepts mapped to EVM equivalents:

| Solana Concept | EVM Equivalent | Explanation |
|---------------|----------------|-------------|
| **Program** | Smart contract | Deployed code. But on Solana, programs are stateless — they don't store data inside themselves. |
| **Account** | Storage slot / contract with balance | All data lives in separate "accounts" (think of them as individual storage containers). The program reads/writes to accounts passed into each transaction. |
| **PDA (Program Derived Address)** | CREATE2 address | A deterministic address derived from seeds (like salt in CREATE2). The program can "sign" on behalf of this address — no private key exists for it. This is how the contract controls funds. |
| **CPI (Cross-Program Invocation)** | External call (`contract.call()`) | Calling another program from within your program. Like calling another contract. |
| **Signer** | `msg.sender` | The wallet that signed the transaction. But on Solana, multiple accounts can be signers in one tx. |
| **Instruction** | Function / method | A callable entry point on the program. Like a public function on a Solidity contract. |
| **Anchor** | Hardhat + OpenZeppelin | The framework used to build this. Handles serialization, account validation, and error handling. |
| **Lamports** | Wei | Smallest unit of SOL (1 SOL = 1,000,000,000 lamports). |
| **ATA (Associated Token Account)** | ERC-20 balance mapping | On EVM, token balances are `mapping(address => uint256)` inside the token contract. On Solana, each wallet needs a separate "token account" for each token. The ATA is the standard deterministic address for "wallet X's account for token Y". |
| **WSOL** | WETH | Wrapped native token. Solana programs work with SPL tokens (like ERC-20s), so native SOL must be wrapped first. |
| **Rent** | N/A (but think gas deposit) | Solana accounts must hold a minimum SOL balance to exist. Think of it as a permanent storage deposit. If an account drops below rent-exempt minimum, it gets garbage collected. |

---

## Contract State (Like Solidity Storage Variables)

### PortalConfig — The "constructor" state

> EVM analogy: These are your contract-level storage variables set in the constructor.

```
PortalConfig {
    authority    — like `owner` in Ownable.sol
    operator     — like a whitelisted relayer/backend address
    paused       — like OpenZeppelin Pausable
    chain_id     — hardcoded to 42161 (Arbitrum)
}
```

There is exactly **one** PortalConfig, stored at a deterministic address (PDA) derived from the seed `"config"`. Think of this as a singleton.

### PortalAccount — Per-deposit metadata

> EVM analogy: Like a struct in a `mapping(bytes32 => Portal)`.

```
PortalAccount {
    owner_hash        — bytes32 identifier (Poseidon hash of the EVM owner)
    recovery          — address that can rescue funds if bridging fails
    is_used           — bool, one-time flag (like a nonce check)
    created_at        — block.timestamp equivalent
    amount_withdrawn  — how much was bridged
    currency_mint     — which token (address(0) equivalent for SOL)
}
```

One PortalAccount is created per bridge execution, keyed by `(owner_hash, recovery)`.

---

## How Addresses (PDAs) Work — The CREATE2 Analogy

On EVM, you can compute a deterministic address with:
```solidity
address vault = address(uint160(uint256(keccak256(abi.encodePacked(
    bytes1(0xff), factory, salt, keccak256(bytecode)
)))));
```

On Solana, the equivalent is a PDA:
```
vault_address = PDA(["portal", owner_hash, recovery_pubkey], program_id)
```

**The critical difference:** On EVM, a CREATE2 address is just an address until you deploy to it. On Solana, a PDA is an address that your program can **sign transactions from** — it acts like a contract-controlled wallet with no private key.

### The Three PDAs in This System

```
Config PDA:     seeds = ["config"]
                One per program. Stores admin settings.

Vault PDA:      seeds = ["portal", owner_hash(32 bytes), recovery_pubkey(32 bytes)]
                One per (owner, recovery) pair. HOLDS THE ACTUAL FUNDS.
                This is the "stealth address" users deposit into.

Portal Meta:    seeds = ["portal_meta", owner_hash(32 bytes), recovery_pubkey(32 bytes)]
                One per vault. Tracks whether bridge has executed.
```

---

## The 10 Functions (Instructions)

### Admin Functions

#### 1. `initialize(operator)`
> EVM: `constructor(address _operator)`

Sets up the contract. Called once. Sets the authority (owner) and operator (backend wallet).

#### 2. `update_config(new_operator?, new_authority?)`
> EVM: `function setOperator(address)` + `function transferOwnership(address)`

Only callable by `authority`. Can update operator and/or transfer ownership.

#### 3. `pause(paused)`
> EVM: OpenZeppelin `Pausable.pause()` / `unpause()`

Only callable by `authority`. When paused, all bridge functions revert.

---

### Vault Creation (The "Stealth Address" System)

#### 4. `create_stealth_sol(owner_hash)`
> EVM: Like deploying a minimal proxy to a CREATE2 address

The operator pre-creates a vault at a deterministic address. This is needed because on Solana, an account must exist before it can receive SOL (unlike EVM where any address can receive ETH).

The vault address is computed as: `PDA(["portal", owner_hash, recovery])` — fully deterministic, anyone can compute it off-chain.

#### 5. `create_stealth_spl_ata(owner_hash)`
> EVM: Like calling `approve()` or setting up a token allowance mapping

Creates a token account (ATA) owned by the vault PDA for a specific SPL token (like USDC). This is necessary because on Solana, you can't just send tokens to any address — the recipient must have a "token account" for that specific token first.

**Think of it this way:** On EVM, your USDC balance is stored inside the USDC contract as `balances[your_address]`. On Solana, your USDC balance lives in a separate account that you own. This instruction creates that account for the vault.

---

### Bridge Functions — Across Protocol

#### 6. `bridge_sol(owner_hash, input_amount, state_seed, quote_params)`
> EVM analogy: Like calling `WETH.deposit()` then `acrossBridge.deposit(...)` in one transaction

**What happens step by step:**

```
1. Check: Is the contract paused? Is the caller the operator?
2. Check: Does the vault have enough SOL? (balance >= amount + rent)
3. Wrap SOL to WSOL
   — Like calling WETH.deposit{value: amount}()
   — Transfers SOL from vault → vault's WSOL token account
   — Calls "sync native" to update the WSOL balance
4. Approve the Across delegate to spend WSOL
   — Like calling WETH.approve(acrossDelegate, amount)
5. Call Across deposit() via CPI
   — Like calling across.deposit(depositor, recipient, inputToken, ...)
   — The vault PDA signs this call (program-controlled signature)
6. Record metadata: mark portal as used, store amount, timestamp
7. Emit event
```

**The Across delegate** is a special PDA derived from all the deposit parameters (recipient, amounts, chain ID, etc.) via keccak256. It's the account that Across uses to pull tokens from the depositor.

#### 7. `bridge_spl(owner_hash, input_amount, state_seed, quote_params)`
> EVM analogy: Like calling `usdc.approve(across, amount)` then `across.deposit(...)`

Same as bridge_sol but simpler — no wrapping needed. Directly approves the Across delegate on the vault's token account and calls Across deposit.

**Important constraint:** The vault's token balance must **exactly equal** `input_amount`. This is like requiring `balanceOf(vault) == amount` — prevents partial bridges.

---

### Bridge Functions — Relay Protocol

#### 8. `bridge_relay_sol(owner_hash, input_amount, relay_amount, fee_amounts, relay_id)`
> EVM: `relayDepository.depositNative{value: amount}(relay_id)`

Transfers the quoted LiFi fees and then deposits the exact `relay_amount` from the vault
into Relay. The `relay_id` is read directly from Relay's serialized instruction in the
LiFi quote; it is not synthesized from LiFi's quote ID. Relay records the portal PDA as
`sender` and the on-curve operator as `depositor`.

#### 9. `bridge_relay_spl(owner_hash, input_amount, relay_amount, fee_amounts, relay_id)`
> EVM: `usdc.approve(relay, amount); relay.depositToken(amount, relay_id)`

Same accounting model as Relay SOL, but for SPL tokens. The contract requires
`relay_amount + sum(fee_amounts) == input_amount`, requires the full vault balance to be
consumed, and caps the total LiFi fee at 1%.

#### 10. `bridge_eco_spl(owner_hash, input_amount, provider_amount, fee_amounts, provider_instruction_data)`

Executes an exact LiFi-quoted Eco SPL instruction. The Eco program ID is hard-coded and
checked on-chain. The operator receives a temporary delegation for exactly
`provider_amount`; the delegation is revoked after CPI and the vault token account must be
empty. LiFi fees use the same full-balance and 1% cap invariants as Relay.

---

### Recovery Functions

#### 11a. `recover_sol(owner_hash)`
> EVM: Like an emergency `withdraw()` callable by a designated recovery address

If bridging fails or funds need to be rescued, the **recovery signer** (the wallet whose public key was used as part of the vault's PDA seeds) can withdraw all SOL from the vault.

**Key insight:** The recovery address is baked into the vault's address derivation. Only the holder of that specific private key can call recover. It's like having a second owner embedded in the CREATE2 salt.

#### 11b. `recover_spl(owner_hash)`
> EVM: Same as above but for ERC-20 tokens, plus it closes the token account (refunds rent)

Transfers all tokens from vault ATA to a recipient, then closes the token account.

---

## How LiFi Quotes Work

LiFi is a bridge aggregator API (like 1inch but for bridges). The production broadcaster
quotes with the on-curve operator wallet, decodes the returned Solana transaction, and
feeds only validated parameters into the appropriate on-chain bridge adapter.

### Quote identity

```
Backend calls: GET https://li.quest/v1/quote
  ?fromChain=1151111081099710    (Solana's chain ID — yes, it's huge)
  ?toChain=42161                 (Arbitrum)
  ?fromToken=EPjFWdd...          (USDC on Solana — this is a base58 address, not 0x)
  ?toToken=0xaf88d065...         (USDC on Arbitrum — normal EVM address)
  ?fromAmount=1000000            (1 USDC in 6 decimals)
  ?fromAddress=<operator>        (the on-curve transaction signer and fee payer)
  ?toAddress=<evm_recipient>     (where to receive on Arbitrum)
  ?allowBridges=relaydepository,eco
```

The portal PDA must not be used as `fromAddress`: it is off-curve, cannot sign LiFi's
transaction, and may have no SOL for transaction fees or temporary account rent. The
operator pays those transaction costs, while the Curvy program moves funds from the PDA.

### Relay and LiFi fee handling

The broadcaster decodes the exact Relay amount and deposit ID from the quote's serialized
transaction. It also decodes every LiFi source-token fee transfer. The on-chain call
reproduces those transfers and enforces:

```
relay_amount + sum(lifi_fee_amounts) == full_portal_balance
sum(lifi_fee_amounts) <= full_portal_balance / 100
```

Relay's `sender` is the portal PDA, so the funds are debited from the vault. Relay's
`depositor` is the operator, matching the identity used to create the quote.

### Eco adapter

For an Eco route the broadcaster retains the exact quoted Eco instruction data and account
ordering, substitutes the operator's source ATA with the portal ATA, and wraps it in
`bridge_eco_spl`. The wrapper accepts only the hard-coded Eco program, grants an exact
temporary token delegation, revokes it after CPI, and verifies that the quoted provider
amount was consumed.

### Direct Across adapter

The repository retains the original direct Across V4 adapter and delegate derivation
below. As of July 2026, however, LiFi does not advertise Across as a Solana-origin bridge
tool, so the production LiFi allowlist uses Relay and Eco.

### Across Delegate PDA — The Complex Part

Across V4 on Solana uses a "delegate" PDA to authorize token transfers. This delegate is derived from ALL the deposit parameters:

```
seed_data = abi.encodePacked(
    depositor,           // 32 bytes (vault PDA)
    recipient,           // 32 bytes
    inputToken,          // 32 bytes
    outputToken,         // 32 bytes
    inputAmount,         // 8 bytes (u64, little-endian)
    outputAmount,        // 32 bytes
    destinationChainId,  // 8 bytes (u64, little-endian)
    exclusiveRelayer,    // 32 bytes
    quoteTimestamp,      // 4 bytes (u32, little-endian)
    fillDeadline,        // 4 bytes (u32, little-endian)
    exclusivityParam,    // 4 bytes (u32, little-endian)
    message              // variable length
)

delegate = PDA(["delegate", keccak256(seed_data)], ACROSS_PROGRAM)
```

> EVM analogy: It's like computing a unique `bytes32 depositHash = keccak256(abi.encode(allParams))` and using that as a mapping key. But instead of a mapping, it becomes an address on Solana.

---

## The Full Flow in Plain English

### Happy Path: User Bridges 1 USDC from Solana to Arbitrum

```
1. SETUP (one-time)
   Backend calls initialize() with its own address as operator.

2. VAULT CREATION
   Backend computes: owner_hash = poseidon(evm_owner_address)
   Backend generates a recovery keypair
   Backend calls create_stealth_spl_ata(owner_hash)
     → This creates a vault at a deterministic address
     → The vault now has a USDC token account ready to receive

3. USER DEPOSIT
   Backend tells the user: "Send 1 USDC to address XYZ on Solana"
   User sends 1 USDC to the vault's token account
   (This is a normal SPL token transfer, no contract interaction)

4. QUOTE
   Backend calls LiFi: "How much will the user get on Arbitrum?"
   LiFi says: "~0.99 USDC after fees, via Relay or Eco"

5. BRIDGE
   Backend calls the matching Relay or Eco wrapper
     → Contract checks vault has exactly 1 USDC
     → Contract reproduces the quoted LiFi source-token fees
     → Contract sends the exact remaining provider amount
     → PortalAccount is created with is_used=true

6. COMPLETION
   The selected provider fills the order on Arbitrum
   User receives ~0.99 USDC on Arbitrum

7. IF SOMETHING GOES WRONG
   Recovery signer calls recover_spl(owner_hash)
     → All USDC returned from vault to a specified recipient
```

---

## Authorization Model

```
                    +-----------+
                    | authority |  (like Ownable.owner)
                    +-----+-----+
                          |
              +-----------+-----------+
              |                       |
        update_config()           pause()
         (change operator         (halt everything)
          or transfer ownership)

                    +----------+
                    | operator |  (like a whitelisted relayer)
                    +-----+----+
                          |
     +--------------------+--------------------+
     |           |              |               |
create_stealth  bridge_sol  bridge_spl  bridge_relay_*  bridge_eco_spl

                    +----------+
                    | recovery |  (embedded in vault address)
                    +-----+----+
                          |
              +-----------+-----------+
              |                       |
         recover_sol()          recover_spl()
```

- **Authority** = Contract owner. Can change operator, pause/unpause.
- **Operator** = Backend service. Can create vaults and execute bridges.
- **Recovery** = Per-vault escape hatch. Can withdraw all funds.

---

## Events (Like Solidity Events)

All events are emitted on-chain and can be indexed by off-chain services.

| Event | When | What It Tells You |
|-------|------|-------------------|
| `PortalConfigInitialized` | `initialize()` | Contract deployed with these settings |
| `OperatorUpdated` | `update_config()` | Operator address changed |
| `AuthorityUpdated` | `update_config()` | Ownership transferred |
| `PauseToggled` | `pause()` | Contract paused or unpaused |
| `StealthSolVaultPrepared` | `create_stealth_sol()` | New SOL vault created at this address |
| `StealthSplAtaPrepared` | `create_stealth_spl_ata()` | New token account created for vault |
| `PortalBridgedSol` | `bridge_sol/relay_sol` | SOL bridged — amount, destination, vault address |
| `PortalBridgedSpl` | `bridge_spl/relay_spl` | Token bridged — amount, mint, destination |
| `PortalBridgedLifiSpl` | `bridge_eco_spl` | SPL token bridged through a validated LiFi provider adapter |
| `PortalRecoveredSol` | `recover_sol()` | SOL recovered from vault |
| `PortalRecoveredSpl` | `recover_spl()` | Tokens recovered from vault |

---

## Error Codes (Like Solidity Custom Errors)

| Code | Name | EVM Equivalent |
|------|------|---------------|
| 6000 | UnauthorizedOperator | `require(msg.sender == operator)` |
| 6001 | UnauthorizedAuthority | `require(msg.sender == owner)` |
| 6003 | InsufficientFunds | `require(balance >= amount)` |
| 6004 | AlreadyUsed | `require(!used[id])` — prevents double-bridge |
| 6005 | InvalidOwnerHash | `require(ownerHash != bytes32(0))` |
| 6008 | EmptyVaultTokenAccount | `require(token.balanceOf(vault) > 0)` |
| 6009 | Paused | `require(!paused)` — from Pausable |
| 6013 | AcrossInputAmountMismatch | `require(token.balanceOf(vault) == inputAmount)` |
| 6014 | AcrossMessageTooLong | `require(message.length <= 512)` |
| 6015 | AcrossInsufficientSolForWrap | `require(vault.balance >= amount + MIN_BALANCE)` |
| 6017 | LiFiAmountMismatch | Provider amount plus fees must consume the full balance |
| 6018 | LiFiFeeTooHigh | Source-token LiFi fee exceeds the 1% on-chain cap |
| 6019 | LiFiFeeRecipientMismatch | Fee amount and recipient counts differ |
| 6020 | UnsupportedLiFiProvider | Provider program is not an approved adapter |
| 6021 | LiFiProviderAmountMismatch | Provider did not consume the quoted amount |
| 6022 | InvalidLiFiProviderInstruction | Provider accounts or payload do not match the approved adapter |
| 6023 | LiFiDestinationMismatch | Provider payload targets a different destination chain |
| 6024 | LiFiRefundRecipientMismatch | Provider refund creator is not the configured operator |

---

## What Would This Look Like in Solidity?

Here's a rough (simplified) Solidity pseudocode of the core logic:

```solidity
contract CurvyPortal is Ownable, Pausable {

    struct Portal {
        bytes32 ownerHash;
        address recovery;
        bool isUsed;
        uint256 amountWithdrawn;
        address currencyToken;
    }

    address public operator;
    mapping(bytes32 => Portal) public portals;

    // Vaults are CREATE2 addresses — deterministic from (ownerHash, recovery)
    // On Solana these are PDAs, same idea

    function bridgeToken(
        bytes32 ownerHash,
        uint256 inputAmount,
        IAcross.DepositParams calldata quote
    ) external whenNotPaused onlyOperator {
        address vault = computeVaultAddress(ownerHash, quote.recovery);

        require(IERC20(usdc).balanceOf(vault) == inputAmount, "amount mismatch");

        // Transfer from vault to Across
        // On Solana: vault PDA signs the approval + Across pulls via delegate
        IERC20(usdc).transferFrom(vault, address(across), inputAmount);

        across.deposit(
            vault,              // depositor
            quote.recipient,    // EVM recipient on Arbitrum
            usdc,               // input token
            quote.outputToken,  // output token on Arbitrum
            inputAmount,
            quote.outputAmount,
            42161,              // Arbitrum
            quote.fillDeadline,
            quote.message
        );

        portals[key].isUsed = true;
        portals[key].amountWithdrawn = inputAmount;
    }

    function recover(bytes32 ownerHash) external {
        address vault = computeVaultAddress(ownerHash, msg.sender);
        // msg.sender must be the recovery address baked into the vault
        IERC20(usdc).transferFrom(vault, msg.sender, balance);
    }
}
```

The key difference on Solana: instead of `transferFrom`, the vault PDA **signs** the transaction itself (program-controlled signature). And instead of a mapping, each portal is a separate account at a deterministic address.

---

## Quick Reference: Solana Token Operations vs EVM

| Operation | EVM | Solana |
|-----------|-----|--------|
| Check token balance | `token.balanceOf(addr)` | Read the vault's ATA account data |
| Transfer tokens | `token.transfer(to, amount)` | CPI to Token Program with vault PDA as signer |
| Approve spender | `token.approve(spender, amount)` | CPI to Token Program: `approve(delegate, amount)` |
| Wrap native token | `weth.deposit{value: amt}()` | Transfer SOL to WSOL ATA + call `sync_native()` |
| Create token account | N/A (automatic) | Must explicitly create ATA before receiving tokens |
| Close token account | N/A | Close account, rent SOL returned to closer |
