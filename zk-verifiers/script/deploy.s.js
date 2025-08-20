"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
// @ts-nocheck
const fs_1 = require("fs");
const hardhat_1 = require("hardhat");
require("dotenv/config");
const main = async () => {
    const CONTRACT_NAMES = [
        "CurvyInsertionVerifier",
        "CurvyAggregationVerifier",
        "CurvyWithdrawVerifier",
    ];
    for (const contractName of CONTRACT_NAMES) {
        const ContractFactory = await hardhat_1.ethers.getContractFactory(contractName);
        const contract = await ContractFactory.deploy();
        await contract.waitForDeployment(1);
        console.log(`Contract [${contractName}] deployed to: ${await contract.getAddress()}`);
        (0, fs_1.writeFileSync)(`./deployments/${process.env.CHAIN_NAME}/${contractName}.address`, await contract.getAddress());
    }
};
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
