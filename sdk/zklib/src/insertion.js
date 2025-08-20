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
exports.randomInsertionData = exports.createInsertionData = void 0;
const fs_1 = __importDefault(require("fs"));
const snarkjs = __importStar(require("snarkjs"));
const utils_1 = require("../src/utils");
// Creates an insertion proof for a given number of notes and tree depth.
// If not enough notes are provided, it generates random notes.
const createInsertionData = async (maxNoteIds, notesTree, userNotes, artifacts) => {
    if (userNotes.length > maxNoteIds) {
        throw new Error(`Too many notes provided. Maximum allowed is ${maxNoteIds}.`);
    }
    const notes = [];
    const noteNonInclusionProofs = [];
    const oldNotesRoot = notesTree.root();
    // Padd the rest of the notes with random notes if not enough are provided
    for (let i = 0; i < maxNoteIds; i += 1) {
        let note;
        if (i >= userNotes.length) {
            note = (0, utils_1.generateNote)(BigInt((0, utils_1.generateRandomInt)(1, 100)), BigInt(0), (0, utils_1.generateRandomBigInt)());
        }
        else {
            note = userNotes[i];
        }
        const nonInclusionProof = await notesTree.generateNonInclusionProof(note.id());
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
    const flattenedSignals = (0, utils_1.flattenVerifyInsertionInputs)(signals);
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
        notes,
        oldNotesRoot,
        newNotesRoot: notesTree.root(),
        noteNonInclusionProofs,
    };
};
exports.createInsertionData = createInsertionData;
// Generates random insertion data for a given number of notes and tree depth.
const randomInsertionData = async (maxNoteIds, treeDepth, artifacts) => {
    const notes = [];
    const notesTree = await (0, utils_1.generateSMTTree)(treeDepth);
    const noteNonInclusionProofs = [];
    const oldNotesRoot = notesTree.root();
    for (let i = 0; i < maxNoteIds; i += 1) {
        const note = (0, utils_1.generateNote)(BigInt((0, utils_1.generateRandomInt)(1, 100)), BigInt(0), (0, utils_1.generateRandomBigInt)());
        const nonInclusionProof = await notesTree.generateNonInclusionProof(note.id());
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
    const flattenedSignals = (0, utils_1.flattenVerifyInsertionInputs)(signals);
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
        notes,
        oldNotesRoot,
        newNotesRoot: notesTree.root(),
        noteNonInclusionProofs,
    };
};
exports.randomInsertionData = randomInsertionData;
