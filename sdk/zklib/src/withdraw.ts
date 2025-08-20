import fs from "fs";
import * as snarkjs from "snarkjs";

import {
    flattenVerifyInsertionInputs,
    flattenVerifyAggregationInputs,
    flattenVerifyWithdrawInputs,
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
export const createWithdrawData = async (
    maxInputs: number,
    maxOutputs: number,
    notesTree: any,
    nullifiersTree: any,
    userWithdraw: { inputNotes: Note[]; outputNotes: Note[] },
    feeNote: Note,
    artifacts: {
        wasmPath: string;
        vKeyFilePath: string;
        zKeyFilePath: string;
    }
) => {
    const DEPTH = 20;
    const destinationAddr = generateRandomBigInt();
    const withdrawFlag = 0n;

    const oldNotesRoot = notesTree.root();
    const oldNullifiersRoot: bigint = nullifiersTree.root();

    const notes = userWithdraw.inputNotes;
    for (const n of notes) await notesTree.insert(n.id());

    /* ────────── Withdraw bus ────────── */
    const w: any = {
        inputNotes: notes.map((n) => n.serialize()),
        signatures: new Array(notes.length),
        noteInclusionProofs: [],
        nullifierNonInclusionProofs: [],
    };

    for (const note of notes) {
        /* inclusion proof for note */
        w.noteInclusionProofs.push(
            (await notesTree.generateInclusionProof(note.id())).proof
        );

        /* non-inclusion proof for nullifier */
        const nullifier = poseidon([
            note.owner.ownerBabyJub[0],
            note.owner.ownerBabyJub[1],
            note.owner.sharedSecret,
        ]);
        w.nullifierNonInclusionProofs.push(
            (await nullifiersTree.generateNonInclusionProof(nullifier)).proof
        );
        await nullifiersTree.insert(nullifier);
    }

    const outputsHash = poseidon(notes.map((n) => n.id()));
    const msgHash = poseidon([outputsHash, destinationAddr, withdrawFlag]);

    for (let i = 0; i < notes.length; i++) {
        w.signatures[i] = sign(
            msgHash,
            (notes[i].privateKeypair as any).privateKeyHex
        );
    }

    /* ────────── flatten & witness ────────── */
    const flattenedSignals = flattenVerifyWithdrawInputs(
        {
            w,
            notesTreeRoot: notesTree.root(),
            oldNullifiersRoot: oldNullifiersRoot,
            destinationAddress: destinationAddr,
            withdrawFlag,
        },
        DEPTH
    );
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
        oldNotesRoot,
        newNotesRoot: notesTree.root(),
        oldNullifiersRoot,
        newNullifiersRoot: nullifiersTree.root(),
        feeNote,
    };
};
