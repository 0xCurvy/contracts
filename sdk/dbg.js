"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const path_1 = __importDefault(require("path"));
const dotenv_1 = __importDefault(require("dotenv"));
const snarkjs = __importStar(require("snarkjs"));
const aggregator_utils_1 = require("./aggregator-utils");
const insertion_1 = require("./zklib/src/insertion");
const aggregate_1 = require("./zklib/src/aggregate");
const utils_1 = require("./zklib/src/utils");
const WITH_ONCHAIN_TX = false;
// Load .env from a parent directory
dotenv_1.default.config({ path: path_1.default.resolve(__dirname, "../.env") });
// ----------------- Configuration Parameters
const aggregatorAddress = "0xa94c9D0042a5846B0E5099b243D3A1F6e6bC6A44";
// Common Circuit parameters
const TREE_DEPTH = 20;
// Insertion Circuit-specific parameters
const MAX_NOTE_IDS = 50;
let circuitArtifactsPathPrefix = `../../curvy-keys/prod/verifyInsertion`;
const INSERTION_CIRCUIT_ARTIFACTS = {
    witnessFilePath: `${circuitArtifactsPathPrefix}/verifyInsertion_20_50_js/witness_calculator.js`,
    wasmPath: `${circuitArtifactsPathPrefix}/verifyInsertion_20_50_js/verifyInsertion_20_50.wasm`,
    vKeyFilePath: `${circuitArtifactsPathPrefix}/keys/verifyInsertion_20_50_verification_key.json`,
    zKeyFilePath: `${circuitArtifactsPathPrefix}/keys/verifyInsertion_20_50_0001.zkey`,
};
// Aggregation Circuit-specific parameters
const MAX_AGGREGATIONS = 10;
const MAX_INPUTS = 10;
const MAX_OUTPUTS = 2;
circuitArtifactsPathPrefix = `../../curvy-keys/prod/verifyAggregation`;
const AGGREGATION_CIRCUIT_ARTIFACTS = {
    witnessFilePath: `${circuitArtifactsPathPrefix}/verifyAggregation_10_10_2_js/witness_calculator.js`,
    wasmPath: `${circuitArtifactsPathPrefix}/verifyAggregation_10_10_2_js/verifyAggregation_10_10_2.wasm`,
    vKeyFilePath: `${circuitArtifactsPathPrefix}/keys/verifyAggregation_10_10_2_verification_key.json`,
    zKeyFilePath: `${circuitArtifactsPathPrefix}/keys/verifyAggregation_10_10_2_0001.zkey`,
};
// ----------------- End of Configuration Parameters
// Initialize the aggregator utils helper
const aggregatorUtils = new aggregator_utils_1.CurvyAggregatorUtils(process.env.RPC_URL, aggregatorAddress, process.env.OPERATOR_PK, process.env.MOCKED_CSUC_PK);
const run = async () => {
    await (0, utils_1.init)();
    // Mocked Native token address inside the Aggregator
    const NATIVE_TOKEN_ID = BigInt(1);
    // Persitent SMT tree for the notes & nullifiers
    const notesTree = await (0, utils_1.generateSMTTree)(TREE_DEPTH);
    const nullifiersTree = await (0, utils_1.generateSMTTree)(TREE_DEPTH);
    const N_INSERTIONS = 2;
    const allNotes = Array(3)
        .fill(0)
        .map((_, i) => (0, utils_1.generateNote)(BigInt(10_000 + i * 100), NATIVE_TOKEN_ID, (0, utils_1.generateRandomBigInt)()));
    // Run multiple note wraps / insertions
    for (let i = 0; i < N_INSERTIONS; i += 1) {
        console.log(`\n\n---- Running insertion #${i + 1} ----\n\n`);
        // Depositing / wrapping a single note into the aggregator
        const notes = [allNotes[i]];
        // Format changed to on-chain compatible format
        const outputNotes = notes.map((note) => note.asOutput());
        if (WITH_ONCHAIN_TX) {
            console.log("Starting note wrap transaction...");
            const wrapTx = (await aggregatorUtils.wrapIntoAggregator(outputNotes, {
                value: 100,
            }));
            console.log("Wrap transaction sent @", wrapTx.hash);
        }
        console.log("Starting note insertion proof generation...");
        const insertionData = await (0, insertion_1.createInsertionData)(MAX_NOTE_IDS, notesTree, notes, INSERTION_CIRCUIT_ARTIFACTS);
        console.log("Insertion data generated successfully. Transforming to Solidity calldata...");
        const calldata = JSON.parse("[" +
            (await snarkjs.groth16.exportSolidityCallData(insertionData.proof, insertionData.publicSignals)) +
            "]");
        const data = {
            a: calldata[0],
            b: calldata[1],
            c: calldata[2],
            inputs: calldata[3],
        };
        if (WITH_ONCHAIN_TX) {
            console.log("Starting operator execution...");
            const processedWrapsTx = (await aggregatorUtils.processWraps(data));
            console.log("Wraps processing executed @", processedWrapsTx.hash);
        }
    }
    // Aggregate two notes
    const inputNotes = [allNotes[0], allNotes[1]];
    const totalInputAmount = inputNotes.reduce((acc, note) => acc + note.amount, BigInt(0));
    // Take fee from the input sum
    const feeAmount = BigInt(Math.floor(Number(totalInputAmount) / Math.floor(1000 / 1)));
    let totalAvailableAmount = totalInputAmount - feeAmount;
    console.log(`Total input amount: ${totalInputAmount.toString()}`);
    console.log(`totalAvailableAmount amount: ${totalAvailableAmount.toString()}`);
    const outputNotes = [];
    for (let i = 0; i < MAX_OUTPUTS; i += 1) {
        const amount = i == MAX_OUTPUTS - 1
            ? totalAvailableAmount
            : totalAvailableAmount / BigInt(3);
        totalAvailableAmount -= amount;
        console.log(`Generating output note #${i + 1} with amount: ${amount.toString()}, remaining: ${totalAvailableAmount.toString()}  `);
        outputNotes.push((0, utils_1.generateNote)(amount, NATIVE_TOKEN_ID, (0, utils_1.generateRandomBigInt)()));
    }
    console.log(`Fee amount: ${feeAmount.toString()}`);
    const userAggregations = [
        {
            inputNotes,
            outputNotes,
        },
    ];
    const feeNote = (0, utils_1.generateNote)(feeAmount, NATIVE_TOKEN_ID, (0, utils_1.generateRandomBigInt)());
    const aggregationData = await (0, aggregate_1.createAggregationData)(MAX_AGGREGATIONS, MAX_INPUTS, MAX_OUTPUTS, notesTree, nullifiersTree, userAggregations, feeNote, AGGREGATION_CIRCUIT_ARTIFACTS);
};
run()
    .then(() => {
    console.log("Debugging Script finished successfully.");
    process.exit(0);
})
    .catch((error) => {
    console.error("Error executing debugging script:", error);
    process.exit(1);
});
