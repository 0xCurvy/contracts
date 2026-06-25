import { spawn } from "node:child_process";
import fs from "node:fs";
import { getEnvironmentParameter, getNetworkParameter } from "../ignition/modules/utils/parameters";

/**
 * Greenfield V2 deployment across ALL configured networks, under a FRESH
 * `<environment>_<network>_v2` deployment-id namespace so the V2 journals stay
 * cleanly separate from the V1 (`<environment>_<network>`) journals:
 *   - aggregator chains (`mainDeployment: true`) get the full V2 stack (fresh
 *     vault + aggregator + independent portal factory) via `Core.ts`;
 *   - every other chain gets the fresh V2 portal factory (+ LiFi wiring) via
 *     `PortalDeployment.ts`.
 *
 * V2 is greenfield — it does NOT upgrade or reference the live V1 proxies, so no
 * `legacyProxies` / `--parameters` file is needed; the modules read
 * owner/salt/lifi/erc20 from environment- and network-parameters, keyed off the
 * deployment-id (`<env>` and `<network>` are the first two `_`-separated parts).
 *
 *   ENVIRONMENT=staging    pnpm hardhat run scripts/deploy-v2.ts
 *   ENVIRONMENT=production  pnpm hardhat run scripts/deploy-v2.ts
 */
function run(cmd: string, args: readonly string[]): Promise<void> {
  return new Promise((resolve, reject) => {
    const proc = spawn(cmd, args, { stdio: "inherit" });
    proc.on("close", (code) => (code === 0 ? resolve() : reject(code)));
  });
}

function getPortalFactoryAddress(deploymentId: string) {
  const deployedAddressesPath = `./ignition/deployments/${deploymentId}/deployed_addresses.json`;
  const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, "utf8"));
  return deployedAddresses["PortalFactoryV2#PortalFactory"];
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
    // Aggregator chains get the full V2 stack (Core); every other chain gets the
    // fresh V2 portal factory only (PortalDeployment). Both deploy the factory.
    const mainDeployment = getNetworkParameter("mainDeployment", networkName);
    const deploymentId = `${environment}_${networkName}_v2`;
    const modulePath = mainDeployment
      ? "./ignition/modules/deployments/v2/Core.ts"
      : "./ignition/modules/deployments/v2/PortalDeployment.ts";

    console.log(`==== ${deploymentId} ${mainDeployment ? "V2 full stack" : "V2 portal factory only"} ====`);

    await run("pnpm", [
      "hardhat",
      "ignition",
      "deploy",
      "--deployment-id",
      deploymentId,
      "--network",
      networkName,
      "--verify",
      modulePath,
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

  console.log("==== Extracting deployed ABIs into SDK ====");
  await run("pnpm", ["extract-abis"]);
}

main().catch(console.error);
