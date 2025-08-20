import fs from "fs";
import * as snarkjs from "snarkjs";

import {
    flattenVerifyInsertionInputs,
    generateKeypair,
    generateNote,
    generateRandomBigInt,
    generateRandomInt,
    generateSMTTree,
    sha256BigInt,
} from "../src/utils";
import { Note, OutputNoteData, SMTree } from "../src/types";
import { aggregator } from "../../types";

// Creates an insertion proof for a given number of notes and tree depth.
// If not enough notes are provided, it generates random notes.
export const createInsertionData = async (
    maxNoteIds: number,
    notesTree: any,
    userNotes: Note[],
    artifacts: {
        wasmPath: string;
        vKeyFilePath: string;
        zKeyFilePath: string;
    }
) => {
    if (userNotes.length > maxNoteIds) {
        throw new Error(
            `Too many notes provided. Maximum allowed is ${maxNoteIds}.`
        );
    }

    const notes: Note[] = [];

    const noteNonInclusionProofs: any = [];
    const oldNotesRoot = notesTree.root();

    // Padd the rest of the notes with random notes if not enough are provided
    for (let i = 0; i < maxNoteIds; i += 1) {
        let note: Note;
        if (i >= userNotes.length) {
            note = generateNote(
                BigInt(generateRandomInt(1, 100)),
                BigInt(0),
                generateRandomBigInt()
            );
        } else {
            note = userNotes[i];
        }
        const nonInclusionProof = await notesTree.generateNonInclusionProof(
            note.id()
        );
        noteNonInclusionProofs.push(nonInclusionProof.proof);

        notes.push(note);
        await notesTree.insert(note.id());
    }

    const signals = {
        oldNotesRoot,
        newNotesRoot: notesTree.root(),
        notes: notes.map((note) => note.asOutput()),
        noteNonInclusionProofs,
    };

    const flattenedSignals = flattenVerifyInsertionInputs(signals);

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
        notes,
        oldNotesRoot,
        newNotesRoot: notesTree.root(),
        noteNonInclusionProofs,
    };
};

// Generates random insertion data for a given number of notes and tree depth.
export const randomInsertionData = async (
    maxNoteIds: number,
    treeDepth: number,
    artifacts: {
        wasmPath: string;
        vKeyFilePath: string;
        zKeyFilePath: string;
    }
) => {
    const notes: Note[] = [];
    const notesTree = await generateSMTTree(treeDepth);

    const noteNonInclusionProofs: any = [];
    const oldNotesRoot = notesTree.root();

    for (let i = 0; i < maxNoteIds; i += 1) {
        const note = generateNote(
            BigInt(generateRandomInt(1, 100)),
            BigInt(0),
            generateRandomBigInt()
        );
        const nonInclusionProof = await notesTree.generateNonInclusionProof(
            note.id()
        );
        noteNonInclusionProofs.push(nonInclusionProof.proof);

        notes.push(note);
        await notesTree.insert(note.id());
    }

    const signals = {
        oldNotesRoot,
        newNotesRoot: notesTree.root(),
        notes: notes.map((note) => note.asOutput()),
        noteNonInclusionProofs,
    };

    const flattenedSignals = flattenVerifyInsertionInputs(signals);

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
        notes,
        oldNotesRoot,
        newNotesRoot: notesTree.root(),
        noteNonInclusionProofs,
    };
};
