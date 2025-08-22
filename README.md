# Curvy Protocol's EVM-contracts

![Curvy Banner](./docs//assets/curvy-banner.png)

This repository contains the Curvy contracts implementations on the EVM-based chains. Chains with different runtime environments (i.e. Starknet, Solana, ...) have their own repositories.

The project is a hybrid between [Hardhat's](https://hardhat.org/) (v2.22.4) and [Foundry's](https://book.getfoundry.sh/) (v1.2.1) development environments, with the main focus on Foundry.

During development, the contracts are tested on the [Ethereum Sepolia](https://sepolia.etherscan.io/) testnet.

## High-level Overview

Currently, the project is divided into two main parts:

- **Curvy Single User Contrac (CSUC)**: A single-user contract that allows users to perform private transfers and withdrawals of both ERC20 and Native tokens.
    - Documentation: [./docs/csuc](docs/csuc/README.md)
- **Curvy Aggregator**: A privacy layer for grouping (aggregating) different input 'notes' that have the same hidden owner.
    - Documentation: [./aggregator/csuc](docs/aggregator/README.md)

## Developer Guide

This section is meant for people who want to contribute to the Curvy project.

### Installation: Prerequisites

**Foundry**:

```bash
curl -L https://foundry.paradigm.xyz | bash && foundryup -i 1.2.1

```

**Hardhat**:

```bash
yarn global add hardhat
```

### Installation: Project Setup

**Foundry**:

```bash
forge install
```

**Hardhat**:

```bash
yarn install
```

### Testing

```bash
forge test -vvvv
```

## Deployment

Environment vars setup (and update):

```bash
cp .env.example .env
```

Run deployment script:

```bash
yarn run deploy
```

## Type Generation

```bash
yarn run typechain:generate
```

## Useful links:

### Ethereum Sepolia

- Add network to Metamask: https://chainlist.org/chain/11155111
- Block Explorer: https://sepolia.etherscan.io
- Sepolia Faucet: https://sepolia-faucet.pk910.de/

### Ethereum Mainnet

- Add network to Metamask: https://chainlist.org/chain/1
- Block Explorer: https://etherscan.io

## License

This work is licensed under the Business Source License 1.1 (BUSL-1.1).
