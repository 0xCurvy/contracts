import fs from "node:fs";
import path from "node:path";
import hre from "hardhat";

export function getEnvironmentAndChainName(): { environment: string; chainName: string } {
  let deploymentId: string | undefined;

  for (let i = 0; i < process.argv.length; i++) {
    if (process.argv[i] === "--deployment-id") {
      deploymentId = process.argv[i + 1];
      break; // Exit loop early once deploymentId is found
    }
  }

  if (!deploymentId) {
    throw new Error("Unable to parse deployment id from args");
  }

  const environment = deploymentId.split("_")[0]; // Extract environment from deploymentId
  const chainName = deploymentId.split("_")[1]; // Extract chainName from deploymentId

  if (!environment || !chainName) {
    throw new Error("Invalid deployment id format. Expected format: 'environment_chainName'");
  }

  if (environment !== "local" && environment !== "staging" && environment !== "production") {
    throw new Error(`Invalid environment '${environment}'. Expected 'staging' or 'production'`);
  }

  return { environment, chainName };
}

export function getDeployedContractAddressOrZero(contractName: string): string {
  const { environment, chainName } = getEnvironmentAndChainName();
  const deploymentId = `${environment}_${chainName}`;

  const filePath = path.resolve(process.cwd(), "ignition", "deployments", deploymentId, "deployed_addresses.json");

  if (!fs.existsSync(filePath)) {
    console.warn(`Deployment file not found for deployment ID '${deploymentId}' returning zero address.`);
    return "0x0000000000000000000000000000000000000000";
  }

  const rawData = fs.readFileSync(filePath, "utf-8");
  const addresses = JSON.parse(rawData);

  if (!addresses[contractName]) {
    return "0x0000000000000000000000000000000000000000";
  }

  return addresses[contractName];
}

export async function assertCurrentNetwork(networkName: string): Promise<void> {
  const network = await hre.network.connect();
  const client = await network.viem.getPublicClient();
  if (client.chain.name !== networkName) {
    throw new Error(`Expected network '${networkName}', but got '${client.chain.name}'`);
  }
}

function getNetworkParameter<T>(parameterName: string): T | null;
function getNetworkParameter<T>(parameterName: string, defaultValue: T): T;
function getNetworkParameter<T>(parameterName: string, defaultValue?: T): T | null {
  const { chainName } = getEnvironmentAndChainName();

  const parameters = readParameters("network-parameters.json");

  if (!parameters[chainName] || !parameters[chainName][parameterName]) {
    return defaultValue ?? null;
  }

  return parameters[chainName][parameterName];
}

function getEnvironmentParameter<T>(parameterName: string): T | null;
function getEnvironmentParameter<T>(parameterName: string, defaultValue: T): T;
function getEnvironmentParameter<T>(parameterName: string, defaultValue?: T): T | null {
  const { environment } = getEnvironmentAndChainName();

  const parameters = readParameters("environment-parameters.json");

  if (!parameters[environment] || !parameters[environment][parameterName]) {
    return defaultValue ?? null;
  }

  return parameters[environment][parameterName];
}

function readParameters(filename: "network-parameters.json" | "environment-parameters.json"): any {
  const filePath = path.resolve(process.cwd(), "ignition", filename);

  if (!fs.existsSync(filePath)) {
    throw new Error("Parameters file not found.");
  }

  const rawData = fs.readFileSync(filePath, "utf-8");
  return JSON.parse(rawData);
}

export { getNetworkParameter, getEnvironmentParameter };
