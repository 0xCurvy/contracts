// @ts-nocheck
import { writeFileSync } from "fs";
import { ethers } from "hardhat";

import "dotenv/config";

const main = async () => {
    const CONTRACT_NAMES = [
        "CurvyInsertionVerifier",
        "CurvyAggregationVerifier",
        "CurvyWithdrawVerifier",
    ];

    for (const contractName of CONTRACT_NAMES) {
        const ContractFactory = await ethers.getContractFactory(contractName);

        const contract = await ContractFactory.deploy();

        await contract.waitForDeployment(1);

        console.log(
            `Contract [${contractName}] deployed to: ${await contract.getAddress()}`
        );

        writeFileSync(
            `./deployments/${process.env.CHAIN_NAME}/${contractName}.address`,
            await contract.getAddress()
        );
    }
};

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
