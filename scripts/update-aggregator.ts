import { spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { getNetworkParameter } from "../ignition/modules/utils/parameters";

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

async function main() {
  const networks = ["arbitrum"];
  const environment = process.env.ENVIRONMENT;

  if (environment !== "staging" && environment !== "production") {
    throw new Error("process.env.ENVIRONMENT must be set to either staging or production");
  }

  for (const networkName of networks) {
    const deploymentId = `${environment}_${networkName}`;

    const legacyByEnv = getNetworkParameter<LegacyProxiesByEnv>("legacyProxies", networkName);
    const legacy = legacyByEnv[environment];
    if (!legacy) {
      throw new Error(`chain '${networkName}' is missing legacyProxies.${environment} in network-parameters.json`);
    }

    console.log(`==== ${deploymentId} aggregator verifiers update ====`);

    // Key must match the module name run below (AggregatorVerifiers → useModule
    // MainDeploymentV2). Previously keyed "MainDeployment", so the params never
    // bound and MainDeploymentV2's required proxy params were undefined.
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
        "./ignition/modules/upgrades/AggregatorVerifiers.ts",
      ]);
    } finally {
      fs.unlinkSync(paramFile);
    }
  }
}

main().catch(console.error);
