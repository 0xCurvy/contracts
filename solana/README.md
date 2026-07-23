# Curvy Portal — Solana

Anchor program that mirrors the EVM Portal Factory: deterministic vault PDAs receive user
deposits, the backend operator atomically bridges them to Arbitrum via LiFi (Across V4 or
Relay Depository), and a SECP256k1 signature path lets users self-recover funds if the
operator ever goes away.

## Program addresses

| Cluster   | Program ID                                          | Notes                                |
| --------- | --------------------------------------------------- | ------------------------------------ |
| mainnet   | `6cHtg7sPLL9NQQuuyepnkud6PskMWV5yxvU2vXfag4qX`      | Production. Authority change = audit |
| devnet    | `HuMaeg6Z81uRhYQ8ct3L3zphbKttULbyhoYGrH1AmLn8`      | Mirrors mainnet program              |
| localnet  | `6cHtg7sPLL9NQQuuyepnkud6PskMWV5yxvU2vXfag4qX`      | Reuses mainnet ID for parity         |

Set in `Anchor.toml` and `programs/curvy-portal/src/lib.rs` (`declare_id!`). They must
match — `anchor build` regenerates IDL + types from `lib.rs`.

---

## Repository layout

```
packages/solana/
├── programs/curvy-portal/      # Anchor program (Rust)
│   └── src/
│       ├── lib.rs              # Entrypoint + instruction registration
│       ├── state.rs            # PortalConfig, PortalAccount
│       ├── error.rs            # Custom error codes
│       ├── constants.rs        # Seeds, domain tags, ARB chain ID
│       └── instructions/       # One file per instruction handler
├── tests/                      # Anchor / mocha integration tests
├── scripts/                    # tsx-runnable utility scripts (devnet/mainnet)
├── runbooks/deployment/        # Surfpool / txtx deploy descriptors
├── migrations/deploy.ts        # `initialize` invocation (config bootstrap)
├── idls/                       # Vendored Across + Relay IDLs (for CPI building)
├── keys/                       # GIT-IGNORED — see "Key management" below
├── .env / .env.example         # GIT-IGNORED — local test fixtures only
├── Anchor.toml
├── Cargo.toml
├── package.json
└── txtx.yml                    # Surfpool environment definitions
```

The on-chain instruction handlers and their TypeScript counterparts in
`packages/backend/src/lib/repositories/portal/chain/solana/instructions.ts` must stay in
sync. If you change account ordering or add an account in Rust, update the builder.

---

## Toolchain

| Tool               | Version                | Install                                                                |
| ------------------ | ---------------------- | ---------------------------------------------------------------------- |
| Rust               | 1.79+                  | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh`      |
| Solana CLI         | 1.18.x or 2.x          | `sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"`        |
| Anchor             | 0.32.1 (pinned)        | `cargo install --git https://github.com/coral-xyz/anchor avm --force` then `avm install 0.32.1 && avm use 0.32.1` |
| Node.js            | 22.16+                 | Per monorepo root                                                      |
| pnpm               | 10.12.1                | Per monorepo root                                                      |
| Surfpool (optional)| latest                 | `brew install txtx/taps/surfpool` (mac) or `snap install surfpool`     |

`anchor --version` must print `anchor-cli 0.32.1`. Mismatched Anchor versions silently
produce incompatible IDLs.

---

## Build

```bash
cd packages/solana
pnpm install              # install JS deps for tests + scripts
anchor build              # compiles the Rust program -> target/deploy/curvy_portal.so
                          # also regenerates target/idl/curvy_portal.json + target/types/
```

If you change `lib.rs`'s `declare_id!`, follow up with:

```bash
anchor keys sync          # rewrites declare_id! and Anchor.toml from target/deploy/*.json
anchor build              # re-compile so the new ID is baked in
```

The IDL at `target/idl/curvy_portal.json` is consumed by:
- `migrations/deploy.ts` (initializes the config PDA)
- `packages/backend/.../solana/instructions.ts` (instruction discriminators are mirrored
  by hand from the IDL — re-run the discriminator hash if you rename an instruction).

---

## Test

### Local (one-shot validator)

```bash
anchor test               # spins up `solana-test-validator`, deploys, runs mocha suite
```

This is the canonical CI flow. Slow on cold caches because it always re-compiles the
program, but it's the only path that mirrors what `anchor deploy` does on devnet/mainnet.

### Surfpool (mainnet fork)

Faster iteration when you need to test against real mainnet account state (Across vault,
Relay depository, real SPL mints). Requires Surfpool installed.

```bash
surfpool start            # starts a mainnet-forking validator on http://127.0.0.1:8899
                          # add --watch to redeploy on every `anchor build`

# in another terminal — deploy via the txtx runbook (instant deployment cheat):
surfpool run deployment

# now run the suite without spinning up another validator:
ANCHOR_PROVIDER_URL=http://127.0.0.1:8899 pnpm test:surfpool
```

If you skip the deployment step the suite errors with *"This program may not be used for
executing instructions"* — Surfnet doesn't auto-deploy.

### Devnet smoke tests

`scripts/derive-portal-devnet.ts`, `scripts/fund-portal-devnet.ts`,
`scripts/bridge-portal-devnet.ts`, `scripts/recover-portal-devnet.ts` exercise the full
deposit → bridge → recover loop against deployed devnet state. Run them via the
`pnpm devnet:*` aliases from `package.json`.

---

## Deploy

### 1. Devnet

```bash
solana config set --url devnet
solana airdrop 2                                # need ~2 SOL for deploy + buffer

# Confirm we'll deploy to the right program ID
anchor keys list

# Deploy via Anchor (uses ~/.config/solana/id.json as upgrade authority by default)
anchor deploy --provider.cluster devnet

# Initialize the config PDA (sets operator + authority on-chain)
PORTAL_OPERATOR_PUBKEY=<base58-of-backend-operator-keypair> \
  pnpm init:devnet
```

`pnpm init:devnet` is idempotent — it skips if the config PDA already exists and prints
the current authority/operator/destination_chain_id.

### 2. Mainnet

The mainnet flow uses the **txtx / Surfpool runbook** because it lets us drive a hardware
wallet or a Squads multisig as the upgrade authority without ever touching the JSON
keypair.

```bash
# 1. Pre-flight checks
anchor build                              # produce a fresh .so
solana config set --url mainnet-beta
solana balance                            # need ~5 SOL on the payer for first deploy

# 2. Inspect what will be deployed
anchor keys list                          # MUST match the mainnet program ID above
sha256sum target/deploy/curvy_portal.so   # record this for change control

# 3. Drive the deployment via Surfpool runbook
#    `runbooks/deployment/main.tx` declares two signers: `payer` and `authority`.
#    Default config uses `svm::web_wallet` — point Phantom / Solflare at the runbook
#    when prompted, or swap in `svm::squads_multisig` / `svm::secp256k1_keypair` for
#    Squads / Ledger workflows (see https://docs.surfpool.run/iac/svm/signers).
surfpool run deployment --env mainnet

# 4. Initialize the config PDA (only on first deploy)
PORTAL_OPERATOR_PUBKEY=<base58-of-prod-operator> \
  pnpm init:mainnet
```

For subsequent upgrades only steps 1–3 are needed — `initialize` is one-time. Use
`update_config` (driven by the authority signer) to rotate the operator without
redeploying.

### 3. Backing the deploy out

Solana program upgrades cannot be hot-rolled back the way contract upgrades can on EVM.
The recovery options are:

1. Re-deploy the previous `.so` (keep every released binary in cold storage with a
   `git rev-parse HEAD` pinned in the filename).
2. If the bug is in `update_config` or `initialize`, call `update_config` with a
   safer operator value — fast, no redeploy.
3. For catastrophic bugs, rotate the upgrade authority to a multisig that's controlled
   by the on-call engineer + a witness, then deploy a patched program.

Always test the upgrade against Surfpool with a forked-mainnet snapshot before pushing
to mainnet.

---

## On-chain config bootstrap (`migrations/deploy.ts`)

After the program is on chain you must call `initialize(operator)` exactly once. The
script reads:

- `provider.wallet` (the deployer's keypair) → becomes the **authority**.
- `PORTAL_OPERATOR_PUBKEY` env var → becomes the **operator** (the only key allowed to
  call `bridge_*` instructions). If unset, the deployer also becomes the operator (a
  warning is printed; never do this in production).
- `idl.address` → the program ID baked into the IDL at build time.

To rotate operator or authority later, call `update_config` from the current authority.
The wiring lives in `programs/curvy-portal/src/instructions/update_config.rs`.

---

## Key management (operator / authority / program)

> The Solana program has three different keys, each with its own threat model and
> rotation policy. Don't conflate them.

### Coming from Hardhat? There's no `anchor-keystore`

Anchor does **not** ship an encrypted keystore like `hardhat-keystore`. The Solana
toolchain expects raw JSON byte-array files (`~/.config/solana/id.json`), and there is
no first-party equivalent to Hardhat's password-protected JSON V3 wallet. The community
has converged on a different stack:

| Hardhat / EVM idiom                      | Solana / Anchor equivalent                                                          |
| ---------------------------------------- | ----------------------------------------------------------------------------------- |
| `hardhat-keystore` (encrypted JSON)      | None native. Use 1Password / SOPS / Vault for at-rest encryption.                   |
| BIP39 passphrase on a JSON keypair       | `solana-keygen new --no-bip39-passphrase` (omit the flag to require one). The on-disk JSON is still plaintext, but the seed → keypair derivation requires the passphrase. |
| Hardhat-Ledger plugin                    | First-class: `solana config set --keypair usb://ledger?key=0`. Anchor respects it. |
| Gnosis Safe                              | [Squads multisig](https://squads.so/) — battle-tested upgrade-authority pattern.    |
| `process.env.PRIVATE_KEY` + dotenv       | Same idea, but the convention is to inject from a secret manager rather than `.env`.|
| Hardhat config `accounts: [...]` array   | Surfpool/txtx runbook signers (`svm::web_wallet`, `svm::secp256k1_keypair`, `svm::squads_multisig`) — see `runbooks/deployment/main.tx`. |

If a team member is used to `hardhat-keystore` and asks "where do I save my key?", the
answer for production is **"nowhere on the deploy machine"** — you wire up the runbook
signer to a hardware wallet or multisig and let txtx prompt at deploy time.

### The three keys at a glance

| Key                 | Purpose                                                | When it signs                                | Lives where (recommended)                       |
| ------------------- | ------------------------------------------------------ | -------------------------------------------- | ----------------------------------------------- |
| **Program keypair** | Determines the program ID. Owns the `.so` slot.        | Deploy time only.                            | Cold storage, single canonical copy.            |
| **Authority**       | Can call `update_config`, `set_upgrade_authority`, redeploy. Highest impact key on the system. | Deployments, operator rotations.             | Squads multisig OR hardware wallet.             |
| **Operator**        | Only key allowed to call `bridge_*`. Hot — must be reachable by the backend at all times. | Every bridge transaction.                    | Backend secret manager (Vault / SOPS / Doppler).|

### Concrete recommendations

#### Program keypair (`keys/<env>/program-keypair.json`)

- Generate once per environment. The public key is the program ID — **changing it
  re-deploys to a new program** and orphans every config PDA derived from the old ID.
- Store the file in a **password manager vault** (1Password / Bitwarden) inside a
  *Solana / mainnet* item. Do **not** store it on the deploy machine after the deploy
  is done — it's only needed during `anchor deploy` for the very first push.
- Anchor will rebuild the `target/deploy/<name>-keypair.json` from scratch on a clean
  checkout; that's a *new random* keypair. Always restore from the vault before
  deploying to production.
- Rotation: only ever needed if the keypair is compromised, in which case you redeploy
  to a new ID and migrate users.

#### Authority keypair (`keys/<env>/authority-keypair.json`)

- This is the high-impact key. Treat it like a contract owner.
- **Best:** bind authority to a [Squads multisig](https://squads.so/) with at least 2
  human signers. The runbook (`runbooks/deployment/main.tx`) already supports
  `svm::squads_multisig` — switch the `signer "authority"` block.
- **Good:** bind to a Ledger hardware wallet held by the engineering lead. Surfpool /
  txtx supports hardware-wallet signing via `svm::secp256k1_keypair`.
- **Acceptable for devnet:** local JSON keypair stored in 1Password. Fetch into
  `keys/devnet/` only at deploy time, then `shred` it.
- **Never:** check the JSON file into git, paste it into Slack, or store it on the
  backend host.
- Rotation: call `set_upgrade_authority` (Solana CLI) followed by an on-chain config
  update if the authority field on `PortalConfig` is also changing.

#### Operator keypair (`keys/<env>/operator-keypair.json`)

- This is a *hot* key — the backend uses it on every bridge transaction. It cannot live
  in 1Password alone.
- **Production**: store the secret-bytes JSON in your secret manager
  (HashiCorp Vault, AWS Secrets Manager, Doppler, SOPS-encrypted file, etc.) and
  inject as the `SOLANA_OPERATOR_PRIVATE_KEY` env var (consumed via `env_json:`
  in `config.example.json`). **Never write it to disk on the host.**
- Limit blast radius: keep the operator's SOL balance to a few-day operating budget.
  Top up via a scripted refill from a treasury wallet, not by putting all funds on
  the operator.
- Rotation: generate a new keypair, `update_config(new_operator)` from the authority,
  then redeploy the backend with the new secret. Old key keeps its SOL but loses
  bridge permission immediately.

### Distributing keys across the team

Pick **one** of the patterns below and stick with it — mixing them defeats the point.

1. **1Password Secrets Automation (recommended for small teams)**
   - Create vaults: `Curvy Solana — Mainnet` (lead engineer + tech lead only) and
     `Curvy Solana — Devnet` (whole engineering team).
   - Store program / authority / operator JSONs as separate Items, with the file
     attached as the *Document* field (not in Notes — Notes get screenshotted).
   - Backend reads operator via `op read` in deploy scripts, never via copy-paste.
   - Membership changes immediately revoke access; no need to rotate keys when an
     engineer leaves.

2. **Multisig + per-engineer hardware wallets**
   - Authority is a Squads multisig; each signer is an individual Ledger.
   - Operator JSON lives only in the production secret manager.
   - Program JSON in 1Password, accessible to the deployer role only.
   - Best property: no single human ever holds the authority key.

3. **SOPS in the repo**
   - Keypairs encrypted with `sops` using AWS KMS / age recipients per environment;
     ciphertexts are committed under `keys/<env>/*.json.enc` (the `keys/` plain-JSON
     directory is gitignored).
   - Engineers decrypt locally as needed: `sops -d keys/devnet/operator-keypair.json.enc > /tmp/op.json`.
   - KMS / age recipient list is the access control surface; rotating it is fast.

Whichever pattern you pick, write it down in `runbooks/` so the on-call rotation
knows exactly where to find each key during an incident.

### What to do if a key was ever in git

If `git log -- packages/solana/keys/` shows any history:

1. **Treat the key as compromised, immediately.**
2. Rotate it on-chain (`update_config` for operator/authority, or redeploy the program
   for the program keypair).
3. Move the funds off the old operator wallet.
4. Purge from history with `git filter-repo` or BFG, then force-push and have everyone
   reclone. Note that anyone who pulled in the meantime still has the key — assume
   external compromise.

### Local test fixtures (`.env`)

The mocha suite in `tests/` consumes `USER1_SECRET_KEY` … `USER4_SECRET_KEY` from
`.env`. Those are *test-only* keypairs — they should never be funded with real assets
or reused on mainnet. The file is git-ignored; copy `.env.example` and run:

```bash
for i in 1 2 3 4; do
  solana-keygen new --no-bip39-passphrase --silent --outfile /tmp/u$i.json
  echo "USER${i}_SECRET_KEY=$(cat /tmp/u$i.json)" >> .env
  shred -u /tmp/u$i.json
done
```

---

## References

- Anchor: <https://www.anchor-lang.com/>
- Solana program model: <https://solana.com/docs/programs>
- Squads multisig (authority pattern): <https://docs.squads.so/>
- Surfpool / txtx runbooks: <https://docs.surfpool.run/>
- LiFi Solana integration: <https://docs.li.fi/>
- Across V4 protocol: <https://docs.across.to/>
