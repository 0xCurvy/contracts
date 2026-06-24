import { spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { getEnvironmentParameter, getNetworkParameter } from "../ignition/modules/utils/parameters";

type LegacyProxies = {
  vaultProxy: string;
  aggregatorProxy: string;
  poseidonT4: string;
};

type LegacyProxiesByEnv = {
  production?: LegacyProxies;
  staging?: LegacyProxies;
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
  return deployedAddresses["PortalFactoryV2#PortalFactoryV2"];
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

  for (const networkName of networks) {
    const deploymentId = `${environment}_${networkName}`;
    const mainDeployment = getNetworkParameter("mainDeployment", networkName);

    if (mainDeployment) {
      const legacyByEnv = getNetworkParameter<LegacyProxiesByEnv>("legacyProxies", networkName);
      const legacy = legacyByEnv[environment];
      if (!legacy) {
        throw new Error(
          `mainDeployment chain '${networkName}' is missing legacyProxies.${environment} in network-parameters.json`,
        );
      }

      console.log(`==== ${deploymentId} main deployment (V2) ====`);

      const parameters = {
        MainDeploymentV2: {
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
          "./ignition/modules/current/MainDeployment.ts",
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
        "./ignition/modules/current/Deployment.ts",
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

  console.log("==== Extracting deployed ABIs into SDK ====");
  await run("pnpm", ["extract-abis"]);
}

main().catch(console.error);
