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
exports.createWithdrawData = void 0;
const fs_1 = __importDefault(require("fs"));
const snarkjs = __importStar(require("snarkjs"));
const utils_1 = require("./utils");
// Creates an insertion proof for a given number of notes and tree depth.
// If not enough notes are provided, it generates random notes.
const createWithdrawData = async (maxInputs, maxOutputs, notesTree, nullifiersTree, userWithdraw, feeNote, artifacts) => {
    const DEPTH = 20;
    const destinationAddr = (0, utils_1.generateRandomBigInt)();
    const withdrawFlag = 0n;
    const oldNotesRoot = notesTree.root();
    const oldNullifiersRoot = nullifiersTree.root();
    const notes = userWithdraw.inputNotes;
    for (const n of notes)
        await notesTree.insert(n.id());
    /* ────────── Withdraw bus ────────── */
    const w = {
        inputNotes: notes.map((n) => n.serialize()),
        signatures: new Array(notes.length),
        noteInclusionProofs: [],
        nullifierNonInclusionProofs: [],
    };
    for (const note of notes) {
        /* inclusion proof for note */
        w.noteInclusionProofs.push((await notesTree.generateInclusionProof(note.id())).proof);
        /* non-inclusion proof for nullifier */
        const nullifier = (0, utils_1.poseidon)([
            note.owner.ownerBabyJub[0],
            note.owner.ownerBabyJub[1],
            note.owner.sharedSecret,
        ]);
        w.nullifierNonInclusionProofs.push((await nullifiersTree.generateNonInclusionProof(nullifier)).proof);
        await nullifiersTree.insert(nullifier);
    }
    const outputsHash = (0, utils_1.poseidon)(notes.map((n) => n.id()));
    const msgHash = (0, utils_1.poseidon)([outputsHash, destinationAddr, withdrawFlag]);
    for (let i = 0; i < notes.length; i++) {
        w.signatures[i] = (0, utils_1.sign)(msgHash, notes[i].privateKeypair.privateKeyHex);
    }
    /* ────────── flatten & witness ────────── */
    const flattenedSignals = (0, utils_1.flattenVerifyWithdrawInputs)({
        w,
        notesTreeRoot: notesTree.root(),
        oldNullifiersRoot: oldNullifiersRoot,
        destinationAddress: destinationAddr,
        withdrawFlag,
    }, DEPTH);
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
        oldNotesRoot,
        newNotesRoot: notesTree.root(),
        oldNullifiersRoot,
        newNullifiersRoot: nullifiersTree.root(),
        feeNote,
    };
};
exports.createWithdrawData = createWithdrawData;
