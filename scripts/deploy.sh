#!/bin/bash

ENV=$1
NETWORK=$2
INPUT_MODULE=$3

if [ -z "$ENV" ] || [ -z "$NETWORK" ] || [ -z "$INPUT_MODULE" ]; then
  echo "❌ Error: Missing parameters."
  echo "Usage: pnpm deploy <env> <network> <module_name>"
  echo "Aliases: vault, aggregator-alpha, portal-factory, token-bridge"
  echo "Example: pnpm deploy staging sepolia portal-factory"
  exit 1
fi

case "$INPUT_MODULE" in
  "vault")
    MODULE_NAME="CurvyVault"
    ;;
  "aggregator-alpha")
    MODULE_NAME="CurvyAggregatorAlpha"
    ;;
  "portal-factory")
    MODULE_NAME="PortalFactory"
    ;;
  "token-bridge")
    MODULE_NAME="TokenBridge"
    ;;
  *)
    MODULE_NAME="$INPUT_MODULE"
    ;;
esac

if [ "$INPUT_MODULE" != "$MODULE_NAME" ]; then
  echo "🔹 Mapped alias '$INPUT_MODULE' ➡️  '$MODULE_NAME'"
fi

if [ "$NETWORK" == "sepolia" ]; then
  DEPLOYMENT_ID="${ENV}_ethereum-sepolia"
else
  DEPLOYMENT_ID="${ENV}_${NETWORK}"
fi

if [ "$ENV" == "production" ]; then
  echo "⚠️  WARNING: You are deploying to a PRODUCTION environment ($NETWORK)!"
  echo "🆔 Deployment ID: $DEPLOYMENT_ID"
  read -p "Are you sure you want to continue? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "🚫 Operation aborted."
      exit 1
  fi
elif [ "$ENV" != "staging" ]; then
  echo "❌ Error: Unknown environment '$ENV'. Use 'staging' or 'production'."
  exit 1
fi


STRATEGY_FLAG=""
ENV_VAR_PREFIX=""

if [[ "$MODULE_NAME" == *"PortalFactory"* ]] || [[ "$MODULE_NAME" == *"TokenBridge"* ]]; then
  echo "⚙️  Configuration for Factory/Bridge detected."
  STRATEGY_FLAG="--strategy create2"
  ENV_VAR_PREFIX="DEPLOY_ENV=$ENV" 
fi

MODULE_PATH="ignition/modules/${MODULE_NAME%.ts}.ts"

CMD="$ENV_VAR_PREFIX npx hardhat ignition deploy --deployment-id $DEPLOYMENT_ID --verify --network $NETWORK $STRATEGY_FLAG $MODULE_PATH"

echo "🚀 Starting deploy..."
echo "📂 ID: $DEPLOYMENT_ID"
echo "🌐 Network: $NETWORK"
echo "🔧 Module: $MODULE_NAME"
if [ ! -z "$ENV_VAR_PREFIX" ]; then echo "ev Env Vars: $ENV_VAR_PREFIX"; fi
echo "📜 Command: $CMD"
echo "-----------------------------------"

eval $CMD