import fs from "fs";
import * as snarkjs from "snarkjs";

import {
    flattenVerifyInsertionInputs,
    flattenVerifyAggregationInputs,
    generateDecoyNote,
    generateKeypair,
    generateNote,
    generateNullifier,
    generateRandomBigInt,
    generateRandomInt,
    generateSMTTree,
    sha256BigInt,
    poseidon,
    sign,
    generateAggregation,
    generateDummyAggregation,
} from "./utils";
import { Note, OutputNoteData, SMTree, Signature } from "./types";
import { aggregator } from "../../types";

// Creates an insertion proof for a given number of notes and tree depth.
// If not enough notes are provided, it generates random notes.
export const createAggregationData = async (
    maxAggregations: number,
    maxInputs: number,
    maxOutputs: number,
    notesTree: any,
    nullifiersTree: any,
    userAggregations: { inputNotes: Note[]; outputNotes: Note[] }[],
    feeNote: Note,
    artifacts: {
        wasmPath: string;
        vKeyFilePath: string;
        zKeyFilePath: string;
    }
) => {
    if (userAggregations.length > maxAggregations) {
        throw new Error(
            `Too many notes provided (${userAggregations.length}). Maximum allowed is ${maxAggregations}.`
        );
    }

    const oldNotesRoot = notesTree.root();
    const oldNullifiersRoot: bigint = nullifiersTree.root();

    const aggregations: any = [];
    const noteNonInclusionProofs: any = [];
    // Padd the rest of the notes with random notes if not enough are provided
    for (let i = 0; i < maxAggregations; i += 1) {
        aggregations.push({
            inputNotes: [],
            outputNotes: [],
            signatures: [],
            ephemeralKeys: [],
            inputNoteInclusionProofs: [],
            nullifierNonInclusionProofs: [],
            outputNoteNonInclusionProofs: [],
            nullifiers: [],
        });
        if (i >= userAggregations.length) {
            aggregations[i] = generateDummyAggregation();
        } else {
            // User provided aggregations - pad if necessary
            aggregations[i].inputNotes = [
                ...userAggregations[i].inputNotes,
                ...Array(maxInputs - userAggregations[i].inputNotes.length)
                    .fill(0)
                    .map((_, j) => {
                        return generateDecoyNote();
                    }),
            ];
            aggregations[i].outputNotes = [
                ...userAggregations[i].outputNotes,
                ...Array(maxOutputs - userAggregations[i].outputNotes.length)
                    .fill(0)
                    .map((_, j) => generateDecoyNote()),
            ];

            // Random ephemeral keys for each input - not checked by the circuits
            const ephemeralKeys: bigint[] = [];
            for (let _i = 0; _i < maxInputs; _i += 1) {
                ephemeralKeys.push(generateRandomBigInt());
            }

            // Generate and sign output hash
            const outputHash = poseidon(
                aggregations[i].outputNotes.map((note) => note.id())
            );
            const ephemeralKeysHash = poseidon(ephemeralKeys);
            const outputAndEphemeralKeysHash = poseidon([
                outputHash,
                ephemeralKeysHash,
            ]);

            // TODO: can each note have its own different owner?
            const signatures: Signature[] = [];
            for (let j = 0; j < maxInputs; j += 1) {
                const inputKeypair =
                    aggregations[i].inputNotes[j].privateKeypair();

                signatures.push(
                    sign(outputAndEphemeralKeysHash, inputKeypair.privKeyHex)
                );
            }

            aggregations[i].signatures = signatures;
            aggregations[i].ephemeralKeys = ephemeralKeys;

            console.log(
                `Aggregation #${i} - input note amounts: ${aggregations[i].inputNotes.map((n) => n.amount)}`
            );
            console.log(
                `Aggregation #${i} - output note amounts: ${aggregations[i].outputNotes.map((n) => n.amount)}`
            );
        }
    }

    for (let i = 0; i < maxAggregations; i += 1) {
        aggregations[i].inputNoteInclusionProofs = [];
        aggregations[i].nullifierNonInclusionProofs = [];
        aggregations[i].outputNoteNonInclusionProofs = [];
        aggregations[i].nullifiers = [];

        for (const note of aggregations[i].inputNotes) {
            aggregations[i].inputNoteInclusionProofs.push(
                (await notesTree.generateInclusionProof(note.id())).proof
            );
            const nullifier = generateNullifier(note);
            aggregations[i].nullifiers.push(nullifier);
            aggregations[i].nullifierNonInclusionProofs.push(
                (await nullifiersTree.generateNonInclusionProof(nullifier))
                    .proof
            );
            await nullifiersTree.insert(nullifier);
        }

        for (const note of aggregations[i].outputNotes) {
            if (note.isDecoy()) {
                // copy the first proof since it won't be checked by the circuit
                return aggregations[0].inputNoteInclusionProofs[0];
            }
            aggregations[i].outputNoteNonInclusionProofs.push(
                (await notesTree.generateNonInclusionProof(note.id())).proof
            );
            await notesTree.insert(note.id());
        }
    }

    const ephemeralKeys = [];
    for (let i = 0; i < maxAggregations; i += 1) {
        ephemeralKeys.push(...aggregations[i].ephemeralKeys);
    }
    const nullifiers: bigint[] = [];
    for (let i = 0; i < maxAggregations; i += 1) {
        for (const note of aggregations[i].inputNotes) {
            nullifiers.push(generateNullifier(note));
            // nullifiersTree.insert(generateNullifier(note));
        }
    }
    const outputNodeIds: bigint[] = [];
    for (let i = 0; i < maxAggregations; i += 1) {
        for (const note of aggregations[i].outputNotes) {
            outputNodeIds.push(note.id());
        }
    }

    // Handle the fee note
    const feeNoteNonInclusionProof = (
        await notesTree.generateNonInclusionProof(feeNote.id())
    ).proof;

    await notesTree.insert(feeNote.id());

    // Get new tree rots
    const newNullifiersRoot: bigint = nullifiersTree.root();
    const newNotesRoot: bigint = notesTree.root();

    // Check sum of inputs === sum of outputs + fee
    let totalInputAmount = BigInt(0);
    let totalOutputAmount = BigInt(0);
    for (const agg of aggregations) {
        for (const note of agg.inputNotes) {
            totalInputAmount += note.amount;
        }
        for (const note of agg.outputNotes) {
            totalOutputAmount += note.amount;
        }
    }
    totalOutputAmount += feeNote.amount;

    if (totalInputAmount !== totalOutputAmount) {
        throw new Error(
            `Total input amount (${totalInputAmount}) does not match total output amount + fee == (${totalOutputAmount})`
        );
    }

    const signals = {
        aggregations: aggregations.map((agg, i: number) => ({
            inputNotes: agg.inputNotes.map((note: Note) => note.serialize()),
            outputNotes: agg.outputNotes.map((note: Note) => note.asOutput()),
            nullifierNonInclusionProof: agg.nullifierNonInclusionProofs, // nullifierInclusionSiblings[treeDepth];
            inputNoteInclusionProof: agg.inputNoteInclusionProofs, // inputNoteInclusionSiblings[treeDepth];
            outputNoteNonInclusionProof: agg.outputNoteNonInclusionProofs, // outputNoteInclusionSiblings[treeDepth];
            outputNoteSignatures: agg.signatures, // Signature() outputNoteSignatures[maxInputNotes][maxOutputNotes];
        })),
        oldNotesRoot,
        oldNullifiersRoot,
        newNullifiersRoot,
        newNotesRoot,
        nullifiers,
        ephemeralKeys,
        feeNote: feeNote.asOutput(),
        feeNoteNonInclusionProof,
        outputNoteIds: [...outputNodeIds, feeNote.id()].map((item) =>
            notesTree.cast(item)
        ),
        nullifiersHash: sha256BigInt(nullifiers),
    };

    fs.writeFileSync("aggregations.json", JSON.stringify(signals, null, 2));

    const flattenedSignals = flattenVerifyAggregationInputs(signals);

    // 1. Generate proof using snarkjs.groth16.fullProve
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(
        flattenedSignals,
        artifacts.wasmPath,
        artifacts.zKeyFilePath
    );

    // 2. Verify proof
    const vKey = JSON.parse(fs.readFileSync(artifacts.vKeyFilePath, "utf8"));
    const res = await snarkjs.groth16.verify(vKey, publicSignals, proof);

    if (res !== true) {
        throw new Error("Proof verification failed");
    }

    return {
        proof,
        publicSignals,
        aggregations,
        oldNotesRoot,
        newNotesRoot: notesTree.root(),
        noteNonInclusionProofs,
        oldNullifiersRoot,
        newNullifiersRoot: nullifiersTree.root(),
        ephemeralKeys,
        feeNote,
        feeNoteNonInclusionProof,
    };
};
