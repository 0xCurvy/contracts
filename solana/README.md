# Curvy Portal - Solana Implementation

Entry bridge portal for Solana that bridges funds to Arbitrum via LiFi.

## Overview

This Anchor program implements deterministic portal PDAs where users deposit SOL or SPL tokens. The backend operator then bridges these funds atomically to Arbitrum in a single transaction via LiFi, maintaining the same security model as the EVM portals.

**Key differences from EVM:**
- PDAs replace CREATE2 for deterministic addresses
- Recovery uses SECP256k1 signature verification via Solana's `secp256k1_recover` syscall (not Ed25519)
- Bridge is two-step: withdraw funds, then execute LiFi instructions in the same transaction

## Program Structure

```
programs/curvy-portal/src/
├── lib.rs                      # Entrypoint + instruction handlers
├── state.rs                    # PortalConfig, PortalAccount structs
├── error.rs                    # Custom error codes
├── constants.rs                # Seeds, domain tags, Arbitrum chain ID
└── instructions/
    ├── initialize.rs           # One-time setup (operator, authority)
    ├── update_config.rs        # Update config (authority-only)
    ├── create_and_bridge_sol.rs # Withdraw SOL + bridge
    ├── create_and_bridge_spl.rs # Withdraw SPL + bridge
    ├── recover_sol.rs          # Recover SOL via secp256k1 sig
    └── recover_spl.rs          # Recover SPL tokens via secp256k1 sig
```

## Instructions

### `initialize(operator: Pubkey)`
**Who:** Deployer (once only)
**What:** Creates the global config PDA with operator, authority, and destination chain ID.

### `update_config(new_operator?, new_authority?)`
**Who:** Authority
**What:** Updates operator wallet or authority pubkey.

### `create_and_bridge_sol(owner_hash: [u8; 32])`
**Who:** Operator
**What:**
1. Creates portal metadata PDA
2. Transfers all SOL from vault PDA to operator wallet
3. Operator then includes LiFi bridge instructions in the same transaction

### `create_and_bridge_spl(owner_hash: [u8; 32])`
**Who:** Operator
**What:** Same as above but for SPL tokens (transfers from vault ATA).

### `recover_sol(owner_hash, secp_sig, recovery_id)`
**Who:** Anyone (payer) with a valid SECP256k1 signature from the recovery key
**What:** Recovers SOL from a vault to any recipient. Uses secp256k1 signature verification.

### `recover_spl(owner_hash, secp_sig, recovery_id)`
**Who:** Anyone (payer) with a valid SECP256k1 signature
**What:** Recovers SPL tokens and closes the vault ATA.

## Account Model

### Portal Metadata PDA
**Seeds:** `["portal_meta", owner_hash (32 bytes), recovery_identifier (32 bytes)]`

Stores per-portal state:
- `owner_hash`: User's owner hash (Poseidon)
- `recovery`: The recovery identifier (SHA-256 of compressed stealth pubkey)
- `is_used`: Whether the portal has been bridged
- `created_at`: Timestamp
- `amount_withdrawn`: Amount transferred for bridging
- `currency_mint`: Token mint (default for SOL)

### Vault PDA
**Seeds:** `["portal", owner_hash, recovery_identifier]`

System Program-owned account that holds user deposits:
- For SOL: raw lamports
- For SPL: ATA (associated token account)

### Config PDA
**Seeds:** `["config"]`

Global singleton:
- `authority`: Who can update config
- `operator`: Who can call bridge/withdraw instructions
- `destination_chain_id`: 42161 (Arbitrum)

## Recovery Flow

Unlike EVM where recovery signer is an Ed25519 keypair, Solana recovery uses **SECP256k1 signatures** because the recovery key is derived from the SECP256k1 stealth key.

Flow:
1. User derives their SECP256k1 stealth private key (from stealth public key via announcement scan)
2. User constructs message: `SHA-256("curvy-solana-recover" || vault_pubkey || recipient_pubkey)`
3. User signs message with SECP256k1 key → `(sig, recovery_id)`
4. Transaction: `recover_sol` or `recover_spl` instruction with `(owner_hash, sig, recovery_id)`
5. Program:
   - Calls `secp256k1_recover` to get the SECP256k1 pubkey
   - Compresses it (33 bytes)
   - Hashes with domain tag: `SHA-256("curvy-solana-recovery-v1" || compressed_pubkey)` → 32-byte recovery identifier
   - Verifies it matches the recovery identifier in vault PDA seeds

## Deployment

### Prerequisites
```bash
# Install Solana CLI
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"

# Install Anchor
cargo install --git https://github.com/coral-xyz/anchor avm --force
avm install 0.30.1
avm use 0.30.1

# Install Node deps
npm install
```

### Generate Program ID
```bash
solana-keygen new --outfile target/deploy/curvy_portal-keypair.json
PROGRAM_ID=$(solana-keygen pubkey target/deploy/curvy_portal-keypair.json)
```

### Update Program ID
Replace in:
- `programs/curvy-portal/src/lib.rs`: `declare_id!("$PROGRAM_ID")`
- `Anchor.toml`: Update all `[programs.*]` sections

### Build
```bash
anchor build
```

### Deploy to Localnet
```bash
solana config set --url localhost
solana-test-validator &  # In another terminal
anchor deploy --provider.cluster localnet
```

### Deploy to Devnet
```bash
solana config set --url devnet
solana airdrop 2
anchor deploy --provider.cluster devnet

# Initialize
export PORTAL_OPERATOR_PUBKEY=$(solana address)
npx ts-node migrations/deploy.ts
```

## Testing

### Local (Localnet with auto-validator)
```bash
anchor test
```

This runs the full integration test suite against a temporary local Solana validator.

### Devnet Manual Testing
After deployment:

```bash
# Derive a vault PDA
node -e "
const { PublicKey } = require('@solana/web3.js');
const programId = new PublicKey('YOUR_PROGRAM_ID');
const ownerHash = Buffer.alloc(32);
ownerHash.writeUInt32BE(12345, 28);
const recovery = PublicKey.default;
const [vault] = PublicKey.findProgramAddressSync(
  [Buffer.from('portal'), ownerHash, recovery.toBuffer()],
  programId
);
console.log('Vault PDA:', vault.toBase58());
"

# Send devnet SOL
solana transfer VAULT_ADDRESS 0.5 --allow-unfunded-recipient

# Call create_and_bridge_sol via Anchor client
```

## Backend Integration

### SolanaPortalChainRepository
**File:** `packages/backend/src/lib/repositories/portal/chain/solana-repository.ts`

Handles:
- Vault PDA derivation
- Balance fetching (SOL + SPL)
- Atomic withdraw + bridge transaction composition

### SolanaPortalBroadcaster
**File:** `packages/backend/src/portal-broadcaster/solana-portal-broadcaster.ts`

Runs alongside EVM broadcaster:
1. Detects pending Solana portals
2. Checks vault balances
3. Gets LiFi quote (Solana → Arbitrum)
4. Executes atomic withdraw + bridge
5. Marks portal as bridged

## Security Notes

1. **Vault PDA Security:** System Program-owned, can only be drained by the portal program via `invoke_signed` with correct PDA seeds.

2. **Recovery Authorization:** SECP256k1 signature verification prevents unauthorized recovery. The signature is bound to a specific vault and recipient (prevents replay).

3. **Single-Use:** `create_and_bridge_*` uses Anchor's `init` constraint, which fails if the account already exists.

4. **Operator Trust:** Operator receives funds and is trusted to bridge them via LiFi. Same trust model as EVM.

5. **No Re-entrancy:** Solana's runtime prevents re-entrancy by design.

## Known Limitations

- Recovery currently requires the caller to construct a SECP256k1 signature. Frontend/CLI tooling needed.
- LiFi quote and bridge execution are separate RPC calls from the backend (not atomic).
- No support for exit bridge (would require approval mechanism on Arbitrum side).

## References

- [Anchor Book](https://www.anchor-lang.com/)
- [Solana Docs](https://docs.solana.com/)
- [LiFi Solana Integration](https://docs.li.fi/)
