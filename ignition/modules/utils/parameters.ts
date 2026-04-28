import fs from "node:fs";
import path from "node:path";

export function getEnvironmentAndNetworkName(): { environment: string; networkName: string } {
  if (process.env.CURVY_NETWORK && process.env.CURVY_ENVIRONMENT) {
    return {
      environment: process.env.CURVY_ENVIRONMENT,
      networkName: process.env.CURVY_NETWORK,
    };
  }

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
  const networkName = deploymentId.split("_")[1]; // Extract chainName from deploymentId

  if (!environment || !networkName) {
    throw new Error("Invalid deployment id format. Expected format: 'environment_chainName'");
  }

  if (environment !== "local" && environment !== "staging" && environment !== "production") {
    throw new Error(`Invalid environment '${environment}'. Expected 'staging' or 'production'`);
  }

  return { environment, networkName };
}

function getNetworkParameter<T>(parameterName: string, networkName?: string): T {
  if (!networkName) {
    networkName = getEnvironmentAndNetworkName().networkName;
  }

  const parameters = readParameters("network-parameters.json");

  if (parameters[networkName] === undefined || parameters[networkName][parameterName] === undefined) {
    throw new Error(`Parameter ${parameterName} not found for network ${networkName}`);
  }

  return parameters[networkName][parameterName];
}

function getEnvironmentParameter<T>(parameterName: string, environment?: string): T {
  if (!environment) {
    environment = getEnvironmentAndNetworkName().environment;
  }

  const parameters = readParameters("environment-parameters.json");

  // audit(2026-Q1): Short-circuit guard bug / operator precedence bug - removed broken `!parameters[env][name] === undefined` check
  if (parameters[environment] === undefined || parameters[environment][parameterName] === undefined) {
    throw new Error(`Parameter ${parameterName} not found for environment ${environment}`);
  }

  return parameters[environment][parameterName];
}

function readParameters(filename: "network-parameters.json" | "environment-parameters.json"): any {
  const filePath = path.resolve(process.cwd(), "ignition", filename);

  if (!fs.existsSync(filePath)) {
    throw new Error("Parameters file not found.");
  }

  const rawData = fs.readFileSync(filePath, "utf-8");
  // audit(2026-Q1): No Error Handling for Invalid JSON
  try {
    return JSON.parse(rawData);
  } catch (error) {
    throw new Error(`Failed to parse ${filename}: ${error instanceof Error ? error.message : String(error)}`);
  }
}

export { getNetworkParameter, getEnvironmentParameter };
