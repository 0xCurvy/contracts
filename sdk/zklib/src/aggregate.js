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
exports.createAggregationData = void 0;
const fs_1 = __importDefault(require("fs"));
const snarkjs = __importStar(require("snarkjs"));
const utils_1 = require("./utils");
// Creates an insertion proof for a given number of notes and tree depth.
// If not enough notes are provided, it generates random notes.
const createAggregationData = async (maxAggregations, maxInputs, maxOutputs, notesTree, nullifiersTree, userAggregations, feeNote, artifacts) => {
    if (userAggregations.length > maxAggregations) {
        throw new Error(`Too many notes provided (${userAggregations.length}). Maximum allowed is ${maxAggregations}.`);
    }
    const oldNotesRoot = notesTree.root();
    const oldNullifiersRoot = nullifiersTree.root();
    const aggregations = [];
    const noteNonInclusionProofs = [];
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
            aggregations[i] = (0, utils_1.generateDummyAggregation)();
        }
        else {
            // User provided aggregations - pad if necessary
            aggregations[i].inputNotes = [
                ...userAggregations[i].inputNotes,
                ...Array(maxInputs - userAggregations[i].inputNotes.length)
                    .fill(0)
                    .map((_, j) => {
                    return (0, utils_1.generateDecoyNote)();
                }),
            ];
            aggregations[i].outputNotes = [
                ...userAggregations[i].outputNotes,
                ...Array(maxOutputs - userAggregations[i].outputNotes.length)
                    .fill(0)
                    .map((_, j) => (0, utils_1.generateDecoyNote)()),
            ];
            // Random ephemeral keys for each input - not checked by the circuits
            const ephemeralKeys = [];
            for (let _i = 0; _i < maxInputs; _i += 1) {
                ephemeralKeys.push((0, utils_1.generateRandomBigInt)());
            }
            // Generate and sign output hash
            const outputHash = (0, utils_1.poseidon)(aggregations[i].outputNotes.map((note) => note.id()));
            const ephemeralKeysHash = (0, utils_1.poseidon)(ephemeralKeys);
            const outputAndEphemeralKeysHash = (0, utils_1.poseidon)([
                outputHash,
                ephemeralKeysHash,
            ]);
            // TODO: can each note have its own different owner?
            const signatures = [];
            for (let j = 0; j < maxInputs; j += 1) {
                const inputKeypair = aggregations[i].inputNotes[j].privateKeypair();
                signatures.push((0, utils_1.sign)(outputAndEphemeralKeysHash, inputKeypair.privKeyHex));
            }
            aggregations[i].signatures = signatures;
            aggregations[i].ephemeralKeys = ephemeralKeys;
            console.log(`Aggregation #${i} - input note amounts: ${aggregations[i].inputNotes.map((n) => n.amount)}`);
            console.log(`Aggregation #${i} - output note amounts: ${aggregations[i].outputNotes.map((n) => n.amount)}`);
        }
    }
    for (let i = 0; i < maxAggregations; i += 1) {
        aggregations[i].inputNoteInclusionProofs = [];
        aggregations[i].nullifierNonInclusionProofs = [];
        aggregations[i].outputNoteNonInclusionProofs = [];
        aggregations[i].nullifiers = [];
        for (const note of aggregations[i].inputNotes) {
            aggregations[i].inputNoteInclusionProofs.push((await notesTree.generateInclusionProof(note.id())).proof);
            const nullifier = (0, utils_1.generateNullifier)(note);
            aggregations[i].nullifiers.push(nullifier);
            aggregations[i].nullifierNonInclusionProofs.push((await nullifiersTree.generateNonInclusionProof(nullifier))
                .proof);
            await nullifiersTree.insert(nullifier);
        }
        for (const note of aggregations[i].outputNotes) {
            if (note.isDecoy()) {
                // copy the first proof since it won't be checked by the circuit
                return aggregations[0].inputNoteInclusionProofs[0];
            }
            aggregations[i].outputNoteNonInclusionProofs.push((await notesTree.generateNonInclusionProof(note.id())).proof);
            await notesTree.insert(note.id());
        }
    }
    const ephemeralKeys = [];
    for (let i = 0; i < maxAggregations; i += 1) {
        ephemeralKeys.push(...aggregations[i].ephemeralKeys);
    }
    const nullifiers = [];
    for (let i = 0; i < maxAggregations; i += 1) {
        for (const note of aggregations[i].inputNotes) {
            nullifiers.push((0, utils_1.generateNullifier)(note));
            // nullifiersTree.insert(generateNullifier(note));
        }
    }
    const outputNodeIds = [];
    for (let i = 0; i < maxAggregations; i += 1) {
        for (const note of aggregations[i].outputNotes) {
            outputNodeIds.push(note.id());
        }
    }
    // Handle the fee note
    const feeNoteNonInclusionProof = (await notesTree.generateNonInclusionProof(feeNote.id())).proof;
    await notesTree.insert(feeNote.id());
    // Get new tree rots
    const newNullifiersRoot = nullifiersTree.root();
    const newNotesRoot = notesTree.root();
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
        throw new Error(`Total input amount (${totalInputAmount}) does not match total output amount + fee == (${totalOutputAmount})`);
    }
    const signals = {
        aggregations: aggregations.map((agg, i) => ({
            inputNotes: agg.inputNotes.map((note) => note.serialize()),
            outputNotes: agg.outputNotes.map((note) => note.asOutput()),
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
        outputNoteIds: [...outputNodeIds, feeNote.id()].map((item) => notesTree.cast(item)),
        nullifiersHash: (0, utils_1.sha256BigInt)(nullifiers),
    };
    fs_1.default.writeFileSync("aggregations.json", JSON.stringify(signals, null, 2));
    const flattenedSignals = (0, utils_1.flattenVerifyAggregationInputs)(signals);
    // 1. Generate proof using snarkjs.groth16.fullProve
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(flattenedSignals, artifacts.wasmPath, artifacts.zKeyFilePath);
    // 2. Verify proof
    const vKey = JSON.parse(fs_1.default.readFileSync(artifacts.vKeyFilePath, "utf8"));
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
exports.createAggregationData = createAggregationData;
