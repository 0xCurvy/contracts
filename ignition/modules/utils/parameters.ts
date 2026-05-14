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

// audit(2026-Q1): No Validation of Address Format
function isValidAddress(value: unknown): value is `0x${string}` {
  return typeof value === "string" && /^0x[0-9a-fA-F]{40}$/.test(value);
}

function getNetworkParameter<T>(parameterName: string, networkName?: string): T {
  if (!networkName) {
    networkName = getEnvironmentAndNetworkName().networkName;
  }

  const parameters = readParameters("network-parameters.json");

  if (parameters[networkName] === undefined) {
    throw new Error(`Parameter ${parameterName} not found for network ${networkName}`);
  }

  // audit(2026-Q1): Missing Null/Undefined Return Handling
  const value = parameters[networkName][parameterName];
  if (value === null || value === undefined) {
    throw new Error(`Parameter '${parameterName}' is null or undefined for network '${networkName}'`);
  }

  return value;
}

function getEnvironmentParameter<T>(parameterName: string, environment?: string): T {
  if (!environment) {
    environment = getEnvironmentAndNetworkName().environment;
  }

  const parameters = readParameters("environment-parameters.json");

  // audit(2026-Q1): Short-circuit guard bug / operator precedence bug - removed broken `!parameters[env][name] === undefined` check
  if (parameters[environment] === undefined) {
    throw new Error(`Parameter ${parameterName} not found for environment ${environment}`);
  }

  // audit(2026-Q1): Missing Null/Undefined Return Handling
  const value = parameters[environment][parameterName];
  if (value === null || value === undefined) {
    throw new Error(`Parameter '${parameterName}' is null or undefined for environment '${environment}'`);
  }

  return value;
}

// audit(2026-Q1): No Validation of Address Format
function getAddressParameter(parameterName: string, source: "network" | "environment", scope?: string): `0x${string}` {
  const value =
    source === "network"
      ? getNetworkParameter<unknown>(parameterName, scope)
      : getEnvironmentParameter<unknown>(parameterName, scope);

  if (!isValidAddress(value)) {
    throw new Error(`Invalid ${parameterName} format: expected a 0x-prefixed 20-byte hex string`);
  }

  return value;
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

export { getNetworkParameter, getEnvironmentParameter, getAddressParameter };
