import { spawn } from "node:child_process";
import { getNetworkParameter } from "../ignition/modules/utils/parameters";

function run(cmd: string, args: readonly string[]): Promise<void> {
  return new Promise((resolve, reject) => {
    const proc = spawn(cmd, args, { stdio: "inherit" });
    proc.on("close", (code) => (code === 0 ? resolve() : reject(code)));
  });
}

async function main() {
  const networks = ["sepolia", "arbitrum", "ethereum", "base", "optimism", "polygon", "bsc", "gnosis", "linea"];
  const environment = process.env.ENVIRONMENT;

  if (environment !== "staging" && environment !== "production") {
    throw new Error("process.env.ENVIRONMENT must be set to either staging or production");
  }

  for (const networkName of networks) {
    const mainDeployment = getNetworkParameter("mainDeployment", networkName);
    if (mainDeployment) {
      console.log(`==== MAIN DEPLOYMENT: ${networkName.toUpperCase()} ====`);
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
    } else {
      console.log(`== ${networkName.toUpperCase()} ==`);
      await run("pnpm", [
        "hardhat",
        "ignition",
        "deploy",
        "--deployment-id",
        `${environment}_${networkName}`,
        "--network",
        networkName,
        "./ignition/modules/Deployment.ts",
      ]);
    }
  }
}

main().catch(console.error);
