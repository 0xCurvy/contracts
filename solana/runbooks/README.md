# solana Runbooks

[![Surfpool](https://img.shields.io/badge/Operated%20with-Surfpool-gree?labelColor=gray)](https://surfpool.run)

## Available Runbooks

### deployment
Deploy programs

## Getting Started

This repository is using [Surfpool](https://surfpool.run) as a part of its development workflow.

Surfpool provides three major upgrades to the Solana development experience:
- **Surfnet**: A local validator that runs on your machine, allowing you fork mainnet on the fly so that you always use the latest chain data when testing your programs.
- **Runbooks**: Bringing the devops best practice of `infrastructure as code` to Solana, Runbooks allow you to have secure, reproducible, and composable scripts for managing on-chain operations & deployments.
- **Surfpool Studio**: An all-local Web UI that gives new levels of introspection into your transactions.

### Installation

Install pre-built binaries:

```console
# macOS (Homebrew)
brew install txtx/taps/surfpool

# Updating surfpool for Homebrew users
brew tap txtx/taps
brew reinstall surfpool

# Linux (Snap Store)
snap install surfpool
```

Install from source:

```console
# Clone repo
git clone https://github.com/txtx/surfpool.git

# Set repo as current directory
cd surfpool

# Build
cargo surfpool-install
```

### Start a Surfnet

```console
$ surfpool start
```

## Resources

Access tutorials and documentation at [docs.surfpool.run](https://docs.surfpool.run) to understand Surfnets and the Runbook syntax, and to discover the powerful features of surfpool.

Additionally, the [Visual Studio Code extension](https://marketplace.visualstudio.com/items?itemName=txtx.txtx) will make writing runbooks easier.

Our [Surfpool 101 Series](https://www.youtube.com/playlist?list=PL0FMgRjJMRzO1FdunpMS-aUS4GNkgyr3T) is also a great place to start learning about Surfpool and its features:
<a href="https://www.youtube.com/playlist?list=PL0FMgRjJMRzO1FdunpMS-aUS4GNkgyr3T">
  <picture>
    <source srcset="https://raw.githubusercontent.com/txtx/surfpool/main/doc/assets/youtube.png">
    <img alt="Surfpool 101 series" style="max-width: 100%;">
  </picture>
</a>

## Quickstart

### List runbooks available in this repository
```console
$ surfpool ls
Name                                    Description
deployment                              Deploy programs
```

### Start a Surfnet, automatically executing the `deployment` runbook on program recompile:
```console
$ surfpool start --watch
```

### Execute an existing runbook
```console
$ surfpool run deployment
```

### Anchor tests (Surfpool / Surfnet)

Tests use `anchor.workspace` and expect the program **already deployed** on the RPC Surfpool exposes (see `txtx.yml`, usually `http://127.0.0.1:8899`).

1. Start Surfnet: `surfpool start` (or `surfpool start --watch` to redeploy from the `deployment` runbook when you rebuild).
2. Deploy at least once: `surfpool run deployment` from the `solana/` directory (after `anchor build` if needed).
3. Run tests against that RPC **without** starting another validator or redeploying from Anchor:
   ```console
   $ cd solana && ANCHOR_PROVIDER_URL=http://127.0.0.1:8899 yarn test:surfpool
   ```
   (`yarn test:surfpool` is `anchor test --skip-local-validator --skip-deploy`.)

If you skip step 2, simulations fail with *This program may not be used for executing instructions* because the program account is missing on Surfnet.

**After `anchor keys sync`:** the program id in `lib.rs` / `Anchor.toml` changes to match `target/deploy/curvy_portal-keypair.json`. Anything previously deployed under the *old* address is ignored — you must deploy again (step 2). If `anchor deploy` stalls on blockhash / many transactions, prefer `surfpool run deployment` (uses `instant_surfnet_deployment` in `runbooks/deployment/main.tx`). Do not interrupt the deploy.

**Verify before tests:** `solana program show <PROGRAM_ID> -u http://127.0.0.1:8899` must list the program as loaded and executable.
