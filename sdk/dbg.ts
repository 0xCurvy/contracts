import path from "path";
import dotenv from "dotenv";
import * as snarkjs from "snarkjs";

import { CurvyAggregatorUtils } from "./aggregator-utils";
import { createInsertionData } from "./zklib/src/insertion";
import { createAggregationData } from "./zklib/src/aggregate";
import {
    init,
    generateNote,
    generateRandomBigInt,
    generateSMTTree,
    generateAggregationSet,
} from "./zklib/src/utils";
import { Note, SMTree } from "./zklib/src/types";
import { ethers } from "ethers";

const WITH_ONCHAIN_TX = false;

// Load .env from a parent directory
dotenv.config({ path: path.resolve(__dirname, "../.env") });

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
const MAX_AGGREGATIONS: number = 10;
const MAX_INPUTS: number = 10;
const MAX_OUTPUTS: number = 2;
circuitArtifactsPathPrefix = `../../curvy-keys/prod/verifyAggregation`;
const AGGREGATION_CIRCUIT_ARTIFACTS = {
    witnessFilePath: `${circuitArtifactsPathPrefix}/verifyAggregation_10_10_2_js/witness_calculator.js`,
    wasmPath: `${circuitArtifactsPathPrefix}/verifyAggregation_10_10_2_js/verifyAggregation_10_10_2.wasm`,
    vKeyFilePath: `${circuitArtifactsPathPrefix}/keys/verifyAggregation_10_10_2_verification_key.json`,
    zKeyFilePath: `${circuitArtifactsPathPrefix}/keys/verifyAggregation_10_10_2_0001.zkey`,
};

// ----------------- End of Configuration Parameters

// Initialize the aggregator utils helper
const aggregatorUtils = new CurvyAggregatorUtils(
    process.env.RPC_URL,
    aggregatorAddress,
    process.env.OPERATOR_PK,
    process.env.MOCKED_CSUC_PK
);

const run = async () => {
    await init();

    // Mocked Native token address inside the Aggregator
    const NATIVE_TOKEN_ID = BigInt(1);

    // Persitent SMT tree for the notes & nullifiers
    const notesTree = await generateSMTTree(TREE_DEPTH);
    const nullifiersTree = await generateSMTTree(TREE_DEPTH);

    const N_INSERTIONS = 2;

    const allNotes: Note[] = Array(3)
        .fill(0)
        .map((_, i) =>
            generateNote(
                BigInt(10_000 + i * 100),
                NATIVE_TOKEN_ID,
                generateRandomBigInt()
            )
        );

    // Run multiple note wraps / insertions
    for (let i = 0; i < N_INSERTIONS; i += 1) {
        console.log(`\n\n---- Running insertion #${i + 1} ----\n\n`);

        // Depositing / wrapping a single note into the aggregator
        const notes: Note[] = [allNotes[i]];

        // Format changed to on-chain compatible format
        const outputNotes = notes.map((note) => note.asOutput());

        if (WITH_ONCHAIN_TX) {
            console.log("Starting note wrap transaction...");
            const wrapTx = (await aggregatorUtils.wrapIntoAggregator(
                outputNotes,
                {
                    value: 100,
                }
            )) as ethers.Transaction;

            console.log("Wrap transaction sent @", wrapTx.hash);
        }

        console.log("Starting note insertion proof generation...");

        const insertionData = await createInsertionData(
            MAX_NOTE_IDS,
            notesTree,
            notes,
            INSERTION_CIRCUIT_ARTIFACTS
        );

        console.log(
            "Insertion data generated successfully. Transforming to Solidity calldata..."
        );

        const calldata = JSON.parse(
            "[" +
                (await snarkjs.groth16.exportSolidityCallData(
                    insertionData.proof,
                    insertionData.publicSignals
                )) +
                "]"
        );

        const data = {
            a: calldata[0],
            b: calldata[1],
            c: calldata[2],
            inputs: calldata[3],
        } as any;

        if (WITH_ONCHAIN_TX) {
            console.log("Starting operator execution...");

            const processedWrapsTx = (await aggregatorUtils.processWraps(
                data
            )) as ethers.Transaction;

            console.log("Wraps processing executed @", processedWrapsTx.hash);
        }
    }

    // Aggregate two notes

    const inputNotes: Note[] = [allNotes[0], allNotes[1]];
    const totalInputAmount = inputNotes.reduce(
        (acc, note) => acc + note.amount,
        BigInt(0)
    );

    // Take fee from the input sum
    const feeAmount: bigint = BigInt(
        Math.floor(Number(totalInputAmount) / Math.floor(1000 / 1))
    );
    let totalAvailableAmount = totalInputAmount - feeAmount;

    console.log(`Total input amount: ${totalInputAmount.toString()}`);
    console.log(
        `totalAvailableAmount amount: ${totalAvailableAmount.toString()}`
    );

    const outputNotes: Note[] = [];
    for (let i = 0; i < MAX_OUTPUTS; i += 1) {
        const amount =
            i == MAX_OUTPUTS - 1
                ? totalAvailableAmount
                : totalAvailableAmount / BigInt(3);
        totalAvailableAmount -= amount;

        console.log(
            `Generating output note #${i + 1} with amount: ${amount.toString()}, remaining: ${totalAvailableAmount.toString()}  `
        );
        outputNotes.push(
            generateNote(amount, NATIVE_TOKEN_ID, generateRandomBigInt())
        );
    }

    console.log(`Fee amount: ${feeAmount.toString()}`);

    const userAggregations = [
        {
            inputNotes,
            outputNotes,
        },
    ];
    const feeNote = generateNote(
        feeAmount,
        NATIVE_TOKEN_ID,
        generateRandomBigInt()
    );

    const aggregationData = await createAggregationData(
        MAX_AGGREGATIONS,
        MAX_INPUTS,
        MAX_OUTPUTS,
        notesTree,
        nullifiersTree,
        userAggregations,
        feeNote,
        AGGREGATION_CIRCUIT_ARTIFACTS
    );
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
