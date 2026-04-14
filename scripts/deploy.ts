import { spawn } from "node:child_process";
import { getEnvironmentParameter, getNetworkParameter } from "../ignition/modules/utils/parameters";
import fs from "node:fs";

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
    const mainDeployment = getNetworkParameter("mainDeployment", networkName);
    if (mainDeployment) {
      console.log(`==== ${environment}_${networkName} main deployment ====`);
      await run("pnpm", [
        "hardhat",
        "ignition",
        "deploy",
        "--deployment-id",
        `${environment}_${networkName}`,
        "--network",
        networkName,
        "--verify",
        "./ignition/modules/MainDeployment.ts",
      ]);

      console.log(`Manually verifying PortalFactory...`);
      await run("pnpm", [
        "hardhat",
        "verify",
        "--network",
        networkName,
        await getPortalFactoryAddress(`${environment}_${networkName}`),
        ownerAddress,
      ]);
    } else {
      console.log(`==== ${environment}_${networkName} portal factory only deployment ====`);
      await run("pnpm", [
        "hardhat",
        "ignition",
        "deploy",
        "--deployment-id",
        `${environment}_${networkName}`,
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
        await getPortalFactoryAddress(`${environment}_${networkName}`),
        ownerAddress,
      ]);
    }
  }
}

main().catch(console.error);
