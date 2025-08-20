"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
require("should");
const utils_1 = require("../src/utils");
const circom_tester_1 = require("circom_tester");
const path_1 = __importDefault(require("path"));
const circuit = await (0, circom_tester_1.wasm)(path_1.default.join(__dirname, "..", "circuits", "instances", "verifyInsertion_20_2.circom"));
describe("Note insertion tests", () => {
    it("should insert two valid notes", async () => {
        const MAX_NOTE_IDS = 2;
        const TREE_DEPTH = 20;
        const notes = [];
        const notesTree = await (0, utils_1.generateSMTTree)(TREE_DEPTH);
        const noteNonInclusionProofs = [];
        const oldNotesRoot = notesTree.root();
        const keypair = (0, utils_1.generateKeypair)();
        for (let i = 0; i < MAX_NOTE_IDS; i += 1) {
            const note = (0, utils_1.generateNote)(BigInt((0, utils_1.generateRandomInt)(1, 100)), BigInt(0), (0, utils_1.generateRandomBigInt)(), keypair.pubKeyBigInt);
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
        signals.oldNotesRoot.should.be.equal(BigInt(0));
        signals.newNotesRoot.should.not.be.equal(BigInt(0));
        const w = await circuit.calculateWitness((0, utils_1.flattenVerifyInsertionInputs)(signals));
        await circuit.checkConstraints(w, true);
    });
    it("should fail two insert notes in tree with invalid roots", async () => {
        const MAX_NOTE_IDS = 2;
        const TREE_DEPTH = 20;
        const notes = [];
        const notesTree = await (0, utils_1.generateSMTTree)(TREE_DEPTH);
        const noteNonInclusionProofs = [];
        const oldNotesRoot = BigInt(3327);
        const keypair = (0, utils_1.generateKeypair)();
        for (let i = 0; i < MAX_NOTE_IDS; i += 1) {
            const note = (0, utils_1.generateNote)(BigInt((0, utils_1.generateRandomInt)(1, 100)), BigInt(0), (0, utils_1.generateRandomBigInt)(), keypair.pubKeyBigInt);
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
        signals.newNotesRoot.should.not.be.equal(BigInt(0));
        try {
            const w = await circuit.calculateWitness((0, utils_1.flattenVerifyInsertionInputs)(signals));
            await circuit.checkConstraints(w, true);
            throw new Error("Constraints should fail!");
        }
        catch (err) {
            return;
        }
    });
    it("should skip to insert zero-ID notes", async () => {
        const MAX_NOTE_IDS = 2;
        const TREE_DEPTH = 20;
        const notes = [];
        const notesTree = await (0, utils_1.generateSMTTree)(TREE_DEPTH);
        const noteNonInclusionProofs = [];
        const oldNotesRoot = notesTree.root();
        const keypair = (0, utils_1.generateKeypair)();
        for (let i = 0; i < MAX_NOTE_IDS; i += 1) {
            const note = (0, utils_1.generateNote)(BigInt(0), BigInt(0), (0, utils_1.generateRandomBigInt)(), keypair.pubKeyBigInt);
            const nonInclusionProof = await notesTree.generateNonInclusionProof(note.id());
            noteNonInclusionProofs.push(nonInclusionProof.proof);
            notes.push(note);
        }
        const signals = {
            oldNotesRoot,
            newNotesRoot: notesTree.root(),
            notes: notes.map((note) => note.asOutput()),
            noteNonInclusionProofs,
        };
        signals.oldNotesRoot.should.be.equal(BigInt(0));
        signals.newNotesRoot.should.be.equal(BigInt(0));
        const w = await circuit.calculateWitness((0, utils_1.flattenVerifyInsertionInputs)(signals));
        await circuit.checkConstraints(w, true);
    });
});
