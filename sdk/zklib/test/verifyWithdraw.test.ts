import "should";
import { wasm as wasm_tester } from "circom_tester";
import path from "path";

import {
  generateKeypair,
  generateNote,
  generateSMTTree,
  generateRandomBigInt,
  poseidon,
  sign,
  flattenVerifyWithdrawInputs,
} from "../src/utils";

(BigInt.prototype as any).toJSON = function () {
  return this.toString();
};

describe("VerifyWithdraw (n = 2, withdrawFlag)", () => {
  it("accepts a valid withdraw", async () => {
    const DEPTH            = 20;
    const destinationAddr  = generateRandomBigInt();
    const withdrawFlag     = 0n;

    const circuit = await wasm_tester(
      path.join(
        __dirname,
        "..",
        "circuits",
        "instances",
        "verifyWithdraw_2_20.circom"
      )
    );

    /* ────────── SMT stabla ────────── */
    const notesTree      = await generateSMTTree(DEPTH);
    const nullifiersTree = await generateSMTTree(DEPTH);
    const oldNullRoot    = nullifiersTree.root();

    /* ────────── ključevi & note ────────── */
    const kp = generateKeypair();

    const notes = [
      generateNote(831_970n, 0n, generateRandomBigInt(), kp.pubKeyBigInt),
      generateNote(216_446n, 0n, generateRandomBigInt(), kp.pubKeyBigInt),
    ];
    for (const n of notes) await notesTree.insert(n.id());

    /* ────────── Withdraw bus ────────── */
    const w: any = {
      inputNotes                 : notes.map((n) => n.serialize()),
      signatures                 : new Array(notes.length),
      noteInclusionProofs        : [],
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
    const msgHash     = poseidon([outputsHash, destinationAddr, withdrawFlag]);

    for (let i = 0; i < notes.length; i++) {
      w.signatures[i] = sign(msgHash, kp.privKeyHex);
    }

    /* ────────── flatten & witness ────────── */
    const flat = flattenVerifyWithdrawInputs(
      {
        w,
        notesTreeRoot     : notesTree.root(),
        oldNullifiersRoot : oldNullRoot,
        destinationAddress: destinationAddr,
        withdrawFlag,
      },
      DEPTH
    );

    const witness = await circuit.calculateWitness(flat, true);
    await circuit.checkConstraints(witness, true);
  });
});
