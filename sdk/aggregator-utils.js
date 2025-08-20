"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CurvyAggregatorUtils = void 0;
const ethers_1 = require("ethers");
const fs_1 = __importDefault(require("fs"));
const CURVY_AGGREGATOR_ARTIFACT = JSON.parse(fs_1.default.readFileSync("./artifacts/src/aggregator/CurvyAggregator.sol/CurvyAggregator.json", "utf8"));
class CurvyAggregatorUtils {
    provider;
    aggregatorContract;
    operator;
    mockedCSUC;
    constructor(rpcURL, aggregatorContractAddress, operatorPrivateKey, mockedCSUCPrivateKey) {
        this.provider = new ethers_1.ethers.JsonRpcProvider(rpcURL);
        this.operator = new ethers_1.ethers.Wallet(operatorPrivateKey, this.provider);
        this.aggregatorContract = new ethers_1.ethers.Contract(aggregatorContractAddress, CURVY_AGGREGATOR_ARTIFACT.abi).connect(this.operator);
        this.mockedCSUC = new ethers_1.ethers.Wallet(mockedCSUCPrivateKey, this.provider);
    }
    async wrapIntoAggregator(notes, params) {
        console.log("Wrapping notes into aggregator...", { params });
        // Only CSUC can call wrap functions
        return await this.aggregatorContract
            .connect(this.mockedCSUC)
            .wrapNative(notes, { value: params?.value || 0 });
    }
    async processWraps(data) {
        console.log("Processing wraps...");
        return await this.aggregatorContract
            .connect(this.operator)
            .processWraps(data);
    }
    async operatorExecute(data) {
        console.log("Executing operator operations...");
        return await this.aggregatorContract
            .connect(this.operator)
            .operatorExecute(data);
    }
}
exports.CurvyAggregatorUtils = CurvyAggregatorUtils;
