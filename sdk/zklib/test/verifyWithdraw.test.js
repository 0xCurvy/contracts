"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
require("should");
const circom_tester_1 = require("circom_tester");
const path_1 = __importDefault(require("path"));
const utils_1 = require("../src/utils");
BigInt.prototype.toJSON = function () {
    return this.toString();
};
describe("VerifyWithdraw (n = 2, withdrawFlag)", () => {
    it("accepts a valid withdraw", async () => {
        const DEPTH = 20;
        const destinationAddr = (0, utils_1.generateRandomBigInt)();
        const withdrawFlag = 0n;
        const circuit = await (0, circom_tester_1.wasm)(path_1.default.join(__dirname, "..", "circuits", "instances", "verifyWithdraw_2_20.circom"));
        /* ────────── SMT stabla ────────── */
        const notesTree = await (0, utils_1.generateSMTTree)(DEPTH);
        const nullifiersTree = await (0, utils_1.generateSMTTree)(DEPTH);
        const oldNullRoot = nullifiersTree.root();
        /* ────────── ključevi & note ────────── */
        const kp = (0, utils_1.generateKeypair)();
        const notes = [
            (0, utils_1.generateNote)(831970n, 0n, (0, utils_1.generateRandomBigInt)(), kp.pubKeyBigInt),
            (0, utils_1.generateNote)(216446n, 0n, (0, utils_1.generateRandomBigInt)(), kp.pubKeyBigInt),
        ];
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
            w.signatures[i] = (0, utils_1.sign)(msgHash, kp.privKeyHex);
        }
        /* ────────── flatten & witness ────────── */
        const flat = (0, utils_1.flattenVerifyWithdrawInputs)({
            w,
            notesTreeRoot: notesTree.root(),
            oldNullifiersRoot: oldNullRoot,
            destinationAddress: destinationAddr,
            withdrawFlag,
        }, DEPTH);
        const witness = await circuit.calculateWitness(flat, true);
        await circuit.checkConstraints(witness, true);
    });
});
