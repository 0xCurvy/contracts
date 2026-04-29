import { spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { getEnvironmentParameter, getNetworkParameter } from "../ignition/modules/utils/parameters";

const LEGACY_ADDRESSES_PATH = path.resolve("./ignition/legacy-proxy-addresses.json");

type LegacyEntry = {
  vaultProxy: string;
  aggregatorProxy: string;
  poseidonT4: string;
};

function run(cmd: string, args: readonly string[]): Promise<void> {
  return new Promise((resolve, reject) => {
    const proc = spawn(cmd, args, { stdio: "inherit" });
    proc.on("close", (code) => (code === 0 ? resolve() : reject(code)));
  });
}

function getPortalFactoryAddress(deploymentId: string) {
  const deployedAddressesPath = `./ignition/deployments/${deploymentId}/deployed_addresses.json`;
  const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));
  return deployedAddresses["PortalFactory#PortalFactory"];
}

function loadLegacyAddresses(): Record<string, LegacyEntry> {
  if (!fs.existsSync(LEGACY_ADDRESSES_PATH)) {
    throw new Error(`Legacy proxy addresses file not found: ${LEGACY_ADDRESSES_PATH}`);
  }
  const parsed = JSON.parse(fs.readFileSync(LEGACY_ADDRESSES_PATH, "utf8"));
  const entries: Record<string, LegacyEntry> = {};
  for (const [key, value] of Object.entries(parsed)) {
    if (key.startsWith("_")) continue;
    entries[key] = value as LegacyEntry;
  }
  return entries;
}

async function main() {
  const networks = [
    "sepolia",
    "arbitrum",
    "ethereum",
    "optimism",
    "base",
    "linea",
    "polygon",
    "bsc",
    "gnosis",
    "tempo",
  ];
  const environment = process.env.ENVIRONMENT;

  if (environment !== "staging" && environment !== "production") {
    throw new Error("process.env.ENVIRONMENT must be set to either staging or production");
  }

  const ownerAddress = getEnvironmentParameter("owner", environment);
  const legacyAddresses = loadLegacyAddresses();

  for (const networkName of networks) {
    const deploymentId = `${environment}_${networkName}`;
    const mainDeployment = getNetworkParameter("mainDeployment", networkName);

    if (mainDeployment) {
      const legacy = legacyAddresses[deploymentId];
      if (!legacy) {
        throw new Error(
          `mainDeployment chain '${networkName}' is missing an entry in legacy-proxy-addresses.json for '${deploymentId}'`,
        );
      }

      console.log(`==== ${deploymentId} main deployment (V1 launch on existing proxies) ====`);

      const parameters = {
        MainDeployment: {
          vaultProxyAddress: legacy.vaultProxy,
          aggregatorProxyAddress: legacy.aggregatorProxy,
          poseidonT4Address: legacy.poseidonT4,
        },
      };

      const paramFile = path.resolve(`./ignition/.deploy-params-${deploymentId}.json`);
      fs.writeFileSync(paramFile, JSON.stringify(parameters, null, 2));

      try {
        await run("pnpm", [
          "hardhat",
          "ignition",
          "deploy",
          "--deployment-id",
          deploymentId,
          "--network",
          networkName,
          "--parameters",
          paramFile,
          "--verify",
          "./ignition/modules/MainDeployment.ts",
        ]);
      } finally {
        fs.unlinkSync(paramFile);
      }

      console.log(`Manually verifying PortalFactory...`);
      await run("pnpm", [
        "hardhat",
        "verify",
        "--network",
        networkName,
        await getPortalFactoryAddress(deploymentId),
        ownerAddress,
      ]);
    } else {
      console.log(`==== ${deploymentId} portal factory only deployment ====`);
      await run("pnpm", [
        "hardhat",
        "ignition",
        "deploy",
        "--deployment-id",
        deploymentId,
        "--network",
        networkName,
        "--verify",
        "./ignition/modules/Deployment.ts",
      ]);

      console.log(`Manually verifying PortalFactory...`);
      await run("pnpm", [
        "hardhat",
        "verify",
        "--network",
        networkName,
        await getPortalFactoryAddress(deploymentId),
        ownerAddress,
      ]);
    }
  }
}

main().catch(console.error);
