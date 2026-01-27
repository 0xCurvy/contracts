import path from "node:path";
import fs from "node:fs";
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

    const environment = deploymentId.split("_")[0];  // Extract environment from deploymentId
    const chainName = deploymentId.split("_")[1];  // Extract chainName from deploymentId

    if (!environment || !chainName) {
        throw new Error("Invalid deployment id format. Expected format: 'environment_chainName'");
    }

    if (environment !== "staging" && environment !== "production") {
        throw new Error(`Invalid environment '${environment}'. Expected 'staging' or 'production'`);
    }

    return {environment, chainName};
}

export function getDeployedContractAddressOnNetwork(networkName: string, contractName: string): string {
    const {environment} = getEnvironmentAndChainName();
    const deploymentId = `${environment}_${networkName}`;

    const filePath = path.resolve(process.cwd(), "ignition", "deployments", deploymentId, "deployed_addresses.json");

    if (!fs.existsSync(filePath)) {
        throw new Error(`Deployment file not found for deployment ID '${deploymentId}'.`);
    }

    const rawData = fs.readFileSync(filePath, "utf-8");
    const addresses = JSON.parse(rawData);

    if (!addresses[contractName]) {
        throw new Error(`Contract '${contractName}' not found in deployment file for deployment ID '${deploymentId}'.`);
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

export async function getCurrentChainId(): Promise<number> {
    const network = await hre.network.connect();
    const client = await network.viem.getPublicClient();

    return client.getChainId();
}

function getParameter<T>(parameterName: string): T | null
function getParameter<T>(parameterName: string, defaultValue: T): T
function getParameter<T>(parameterName: string, defaultValue?: T): T | null {
    const {chainName} = getEnvironmentAndChainName();

    const filePath = path.resolve(process.cwd(), "ignition", "parameters.json");

    if (!fs.existsSync(filePath)) {
        throw new Error("Parameters file not found.");
    }

    const rawData = fs.readFileSync(filePath, "utf-8");
    const parameters = JSON.parse(rawData);

    if (!parameters[chainName] || !parameters[chainName][parameterName]) {
        return defaultValue ?? null;
    }

    return parameters[chainName][parameterName];
}

export {getParameter};