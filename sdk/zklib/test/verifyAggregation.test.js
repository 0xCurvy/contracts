"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
require("should");
const utils_1 = require("../src/utils");
const circom_tester_1 = require("circom_tester");
const path_1 = __importDefault(require("path"));
const circuit = await (0, circom_tester_1.wasm)(path_1.default.join(__dirname, "..", "circuits", "instances", "verifyAggregation_2_2_2.circom"));
describe("Note aggregation tests", () => {
    it("should aggregate two valid notes", async () => {
        const MAX_AGGREGATIONS = 2;
        const MAX_INPUTS = 2;
        const MAX_OUTPUTS = 2;
        const TREE_DEPTH = 20;
        const feeKeypair = (0, utils_1.generateKeypair)();
        const feeSecret = (0, utils_1.generateRandomBigInt)();
        const res = await (0, utils_1.generateAggregationSet)(MAX_AGGREGATIONS, MAX_INPUTS, MAX_OUTPUTS, feeKeypair.pubKeyBigInt, feeSecret, TREE_DEPTH, true, 1);
        const w = await circuit.calculateWitness((0, utils_1.flattenVerifyAggregationInputs)(res));
        await circuit.checkConstraints(w, true);
    });
});
