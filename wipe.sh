#!/bin/bash
set -ex

#
# This file serves as an easy way to iterate on staging without having to create multiple contract versions
# - If you're upgrading CurvyAggregatorAlpha without changing the version: see `# Wiping Aggregator`
# - If you're upgrading CurvyVault without changing the version: see `## Wiping CurvyVault`
#
# And if you're just deploying a new version of PortalFactory:
# - For Main deployments (networks with Aggregator and CurvyVault) consult `## Wiping PortalFactory`
# - For PortalFactory only deployments (networks that only bridge to Main deployment network) consult `Portal factory only`

# Main

## Wiping PortalFactory

#pnpm hardhat ignition wipe staging_linea MainDeploymentModule#PortalFactory~PortalFactory_V5.updateConfig
#pnpm hardhat ignition wipe staging_linea MainDeploymentModule#CurvyAggregatorAlpha~CurvyAggregatorAlphaV5.updateConfig
#pnpm hardhat ignition wipe staging_linea PortalFactory#PortalFactory_V5
#pnpm hardhat ignition wipe staging_linea PortalFactory#ReadEvent_PortalFactory_V5
#pnpm hardhat ignition wipe staging_linea PortalFactory#CreateX_PortalFactory_V5

## Wiping Aggregator

#pnpm hardhat ignition wipe staging_linea MainDeploymentModule#CurvyAggregatorAlpha~CurvyAggregatorAlphaV5.updateConfig
#pnpm hardhat ignition wipe staging_linea CurvyAggregatorAlpha#UpdateConfig_withdrawVerifierV3
#pnpm hardhat ignition wipe staging_linea CurvyAggregatorAlpha#withdrawVerifierV3
#pnpm hardhat ignition wipe staging_linea CurvyAggregatorAlpha#CurvyAggregatorAlphaV4.upgradeToAndCall
#pnpm hardhat ignition wipe staging_linea CurvyAggregatorAlpha#CurvyAggregatorAlphaV5Implementation
#pnpm hardhat ignition wipe staging_linea MainDeploymentModule#CurvyVault~CurvyVaultV5.setCurvyAggregatorAddress
#pnpm hardhat ignition wipe staging_linea CurvyAggregatorAlpha#CurvyAggregatorAlphaV5

## Wiping CurvyVault

#pnpm hardhat ignition wipe staging_linea MainDeploymentModule#CurvyVault~CurvyVaultV5.setCurvyAggregatorAddress
#pnpm hardhat ignition wipe staging_linea CurvyVault#CurvyVaultV5
#pnpm hardhat ignition wipe staging_linea CurvyVault#CurvyVaultV5Implementation
#pnpm hardhat ignition wipe staging_linea CurvyVault#CurvyVaultV4.upgradeToAndCall

# Portal factory only

#pnpm hardhat ignition wipe staging_linea DeploymentModule#PortalFactory~PortalFactory.updateConfig
#pnpm hardhat ignition wipe staging_linea PortalFactory#PortalFactory
#pnpm hardhat ignition wipe staging_linea PortalFactory#ReadEvent_PortalFactory
#pnpm hardhat ignition wipe staging_linea PortalFactory#CreateX_PortalFactory
