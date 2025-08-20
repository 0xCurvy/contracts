import "should";
import {
  flattenVerifyInsertionInputs,
  generateKeypair,
  generateNote,
  generateRandomBigInt,
  generateRandomInt,
  generateSMTTree,
  sha256BigInt,
} from "../src/utils";
import { wasm as wasm_tester } from "circom_tester";
import path from "path";
import { Note } from "../src/types";

const circuit = await wasm_tester(
  path.join(
    __dirname,
    "..",
    "circuits",
    "instances",
    "verifyInsertion_20_2.circom"
  )
);

describe("Note insertion tests", () => {
  it("should insert two valid notes", async () => {
    const MAX_NOTE_IDS: number = 2;
    const TREE_DEPTH = 20;

    const notes: Note[] = [];
    const notesTree = await generateSMTTree(TREE_DEPTH);

    const noteNonInclusionProofs: any = [];
    const oldNotesRoot = notesTree.root();

    const keypair = generateKeypair();

    for (let i = 0; i < MAX_NOTE_IDS; i += 1) {
      const note = generateNote(
        BigInt(generateRandomInt(1, 100)),
        BigInt(0),
        generateRandomBigInt(),
        keypair.pubKeyBigInt
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

    signals.oldNotesRoot.should.be.equal(BigInt(0));
    signals.newNotesRoot.should.not.be.equal(BigInt(0));

    const w = await circuit.calculateWitness(
      flattenVerifyInsertionInputs(signals)
    );

    await circuit.checkConstraints(w, true);
  });

  it("should fail two insert notes in tree with invalid roots", async () => {
    const MAX_NOTE_IDS: number = 2;
    const TREE_DEPTH = 20;

    const notes: Note[] = [];
    const notesTree = await generateSMTTree(TREE_DEPTH);

    const noteNonInclusionProofs: any = [];
    const oldNotesRoot = BigInt(3327);

    const keypair = generateKeypair();

    for (let i = 0; i < MAX_NOTE_IDS; i += 1) {
      const note = generateNote(
        BigInt(generateRandomInt(1, 100)),
        BigInt(0),
        generateRandomBigInt(),
        keypair.pubKeyBigInt
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

    signals.newNotesRoot.should.not.be.equal(BigInt(0));

    try {
      const w = await circuit.calculateWitness(
        flattenVerifyInsertionInputs(signals)
      );

      await circuit.checkConstraints(w, true);
      throw new Error("Constraints should fail!");
    } catch (err) {
      return;
    }
  });

  it("should skip to insert zero-ID notes", async () => {
    const MAX_NOTE_IDS: number = 2;
    const TREE_DEPTH = 20;

    const notes: Note[] = [];
    const notesTree = await generateSMTTree(TREE_DEPTH);

    const noteNonInclusionProofs: any = [];
    const oldNotesRoot = notesTree.root();

    const keypair = generateKeypair();

    for (let i = 0; i < MAX_NOTE_IDS; i += 1) {
      const note = generateNote(
        BigInt(0),
        BigInt(0),
        generateRandomBigInt(),
        keypair.pubKeyBigInt
      );
      const nonInclusionProof = await notesTree.generateNonInclusionProof(
        note.id()
      );
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

    const w = await circuit.calculateWitness(
      flattenVerifyInsertionInputs(signals)
    );

    await circuit.checkConstraints(w, true);
  });
});
