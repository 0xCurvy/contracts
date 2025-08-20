import { ethers } from "ethers";
import fs from "fs";

import { aggregator } from "./types";

const CURVY_AGGREGATOR_ARTIFACT = JSON.parse(
    fs.readFileSync(
        "./artifacts/src/aggregator/CurvyAggregator.sol/CurvyAggregator.json",
        "utf8"
    )
);

export class CurvyAggregatorUtils {
    private provider: ethers.JsonRpcProvider;
    private aggregatorContract: aggregator.CurvyAggregator;
    private operator: ethers.Signer;
    private mockedCSUC: ethers.Signer;

    constructor(
        rpcURL: string,
        aggregatorContractAddress: string,
        operatorPrivateKey: string,
        mockedCSUCPrivateKey: string
    ) {
        this.provider = new ethers.JsonRpcProvider(rpcURL);

        this.operator = new ethers.Wallet(operatorPrivateKey, this.provider);

        this.aggregatorContract = new ethers.Contract(
            aggregatorContractAddress,
            CURVY_AGGREGATOR_ARTIFACT.abi
        ).connect(this.operator) as aggregator.CurvyAggregator;

        this.mockedCSUC = new ethers.Wallet(
            mockedCSUCPrivateKey,
            this.provider
        );
    }

    async wrapIntoAggregator(
        notes: aggregator.CurvyAggregator_Types.NoteStruct[],
        params?: any
    ): Promise<ethers.ContractTransaction> {
        console.log("Wrapping notes into aggregator...", { params });

        // Only CSUC can call wrap functions
        return await this.aggregatorContract
            .connect(this.mockedCSUC)
            .wrapNative(notes, { value: params?.value || 0 });
    }

    async processWraps(
        data: aggregator.CurvyAggregator_Types.WrappingZKPStruct
    ): Promise<ethers.ContractTransaction> {
        console.log("Processing wraps...");

        return await this.aggregatorContract
            .connect(this.operator)
            .processWraps(data);
    }

    async operatorExecute(
        data: aggregator.CurvyAggregator_Types.ActionExecutionZKPStruct
    ): Promise<ethers.ContractTransaction> {
        console.log("Executing operator operations...");

        return await this.aggregatorContract
            .connect(this.operator)
            .operatorExecute(data);
    }
}
