"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateDecoyNote = exports.generateAggregationSet = exports.generateNullifier = exports.generateDummyAggregation = exports.generateAggregation = exports.sign = exports.generateSMTTree = exports.generateNote = exports.generateKeypair = exports.padArray = exports.poseidon = exports.generateRandomInt = exports.generateRandomBigInt = exports.flattenVerifyWithdrawInputs = exports.flattenWithdrawBus = exports.flattenVerifyAggregationInputs = exports.flattenAggregationBus = exports.flattenVerifyInsertionInputs = exports.flattenSignatureBus = exports.flattenOutputNoteBus = exports.flattenNoteBus = exports.flattenInclusionProofBus = exports.flattenNonInclusionProofBus = exports.sha256BigInt = exports.serializeJson = exports.init = void 0;
const circomlibjs_1 = require("circomlibjs");
const crypto_1 = require("crypto");
const circomlibjs_2 = require("circomlibjs");
const crypto_2 = require("crypto");
let poseidonRaw;
let eddsa;
const init = async () => {
    poseidonRaw = await (0, circomlibjs_1.buildPoseidon)();
    eddsa = await (0, circomlibjs_1.buildEddsa)();
};
exports.init = init;
// Monkey patching BigInt toJSON method for it to work in JSON.stringify
BigInt.prototype.toJSON = function () {
    return this.toString();
};
/**
 * Stringify json with bigints
 * @param obj
 * @returns
 */
const serializeJson = (obj) => {
    return JSON.stringify(obj, (_, v) => (typeof v === "bigint" ? v.toString() : v), 2);
};
exports.serializeJson = serializeJson;
const sha256BigInt = (inputs) => {
    const buffer = Buffer.alloc(inputs.length * 32);
    const mask = BigInt("0xffffffffffffffff");
    inputs.forEach((value, index) => {
        const offset = index * 32;
        let valueX = (value >> BigInt(192)) & mask;
        buffer.writeBigUInt64BE(valueX, offset);
        valueX = (value >> BigInt(128)) & mask;
        buffer.writeBigUInt64BE(valueX, offset + 8);
        valueX = (value >> BigInt(64)) & mask;
        buffer.writeBigUInt64BE(valueX, offset + 16);
        buffer.writeBigUInt64BE(value & mask, offset + 24);
    });
    return BigInt("0x" + (0, crypto_2.createHash)("sha256").update(buffer).digest("hex"));
};
exports.sha256BigInt = sha256BigInt;
const flattenNonInclusionProofBus = (proof) => {
    return [...proof.siblings, proof.isOld0, proof.key, proof.value];
};
exports.flattenNonInclusionProofBus = flattenNonInclusionProofBus;
const flattenInclusionProofBus = (proof) => {
    return [...proof.siblings];
};
exports.flattenInclusionProofBus = flattenInclusionProofBus;
const flattenNoteBus = (note) => {
    return [
        ...note.owner.ownerBabyJub,
        note.owner.sharedSecret,
        note.amount,
        note.token,
    ];
};
exports.flattenNoteBus = flattenNoteBus;
const flattenOutputNoteBus = (note) => {
    return [note.ownerHash, note.amount, note.token];
};
exports.flattenOutputNoteBus = flattenOutputNoteBus;
const flattenSignatureBus = (sig) => {
    return [sig.S, ...sig.R8];
};
exports.flattenSignatureBus = flattenSignatureBus;
/**
 * Flatten input busses for insertion verification circuit
 * @param obj
 * @returns
 */
const flattenVerifyInsertionInputs = (obj) => {
    return {
        ...obj,
        notes: obj.notes.map((note) => (0, exports.flattenOutputNoteBus)(note)).flat(),
        noteNonInclusionProofs: obj.noteNonInclusionProofs.map((proof) => (0, exports.flattenNonInclusionProofBus)(proof)),
    };
};
exports.flattenVerifyInsertionInputs = flattenVerifyInsertionInputs;
const flattenAggregationBus = (agg) => {
    return [
        ...agg.inputNotes.map((note) => (0, exports.flattenNoteBus)(note)).flat(),
        ...agg.outputNotes
            .map((note) => (0, exports.flattenOutputNoteBus)(note))
            .flat(),
        ...agg.nullifierNonInclusionProof
            .map((proof) => (0, exports.flattenNonInclusionProofBus)(proof))
            .flat(), // nullifierInclusionSiblings[treeDepth];
        ...agg.inputNoteInclusionProof
            .map((proof) => (0, exports.flattenInclusionProofBus)(proof))
            .flat(), // inputNoteInclusionSiblings[treeDepth];
        ...agg.outputNoteNonInclusionProof
            .map((proof) => (0, exports.flattenNonInclusionProofBus)(proof))
            .flat(), // outputNoteInclusionSiblings[treeDepth];
        ...agg.outputNoteSignatures
            .map((sig) => (0, exports.flattenSignatureBus)(sig))
            .flat(), // Signature() outputNoteSignatures[maxInputNotes][maxOutputNotes];
    ];
};
exports.flattenAggregationBus = flattenAggregationBus;
/**
 * Flatten input busses for insertion aggregation circuit
 * @param obj
 * @returns
 */
const flattenVerifyAggregationInputs = (obj) => {
    const allInputs = {
        ...obj,
        aggregations: obj.aggregations
            .map((agg) => (0, exports.flattenAggregationBus)(agg))
            .flat(),
        ephemeralKeys: obj.ephemeralKeys,
        feeNote: (0, exports.flattenOutputNoteBus)(obj.feeNote),
        feeNoteNonInclusionProof: (0, exports.flattenNonInclusionProofBus)(obj.feeNoteNonInclusionProof),
        nullifiersHash: obj.nullifiersHash,
    };
    // Removing output signals
    delete allInputs.nullifiers;
    delete allInputs.outputNoteIds;
    return allInputs;
};
exports.flattenVerifyAggregationInputs = flattenVerifyAggregationInputs;
const flattenWithdrawBus = (bus, treeDepth) => [
    // 1) inputNotes
    ...bus.inputNotes.map((n) => (0, exports.flattenNoteBus)(n)).flat(),
    // 2) signatures
    ...bus.signatures.map((s) => (0, exports.flattenSignatureBus)(s)).flat(),
    // 3) noteInclusionProofs  → just siblings
    ...bus.noteInclusionProofs
        .map((p) => (0, exports.flattenInclusionProofBus)(p))
        .flat(), // nInputs * treeDepth
    // 4) nullifierNonInclusionProofs → siblings + isOld0 + key + value
    ...bus.nullifierNonInclusionProofs
        .map((p) => (0, exports.flattenNonInclusionProofBus)(p))
        .flat(), // nInputs * (treeDepth + 3)
];
exports.flattenWithdrawBus = flattenWithdrawBus;
/**
 * Flatten input busses for VerifyWithdraw circuit
 * @param obj
 * @returns
 */
const flattenVerifyWithdrawInputs = (obj, treeDepth) => ({
    w: (0, exports.flattenWithdrawBus)(obj.w, treeDepth),
    notesTreeRoot: obj.notesTreeRoot,
    oldNullifiersRoot: obj.oldNullifiersRoot,
    destinationAddress: obj.destinationAddress,
    withdrawFlag: obj.withdrawFlag,
});
exports.flattenVerifyWithdrawInputs = flattenVerifyWithdrawInputs;
/**
 * Generate random bigint value
 * @param bytes
 * @returns
 */
const generateRandomBigInt = (bytes = 31) => BigInt("0x" + (0, crypto_1.randomBytes)(bytes).toString("hex"));
exports.generateRandomBigInt = generateRandomBigInt;
/**
 * Generate random integer in range [min, max]
 * @param min
 * @param max
 * @returns
 */
const generateRandomInt = (min, max) => Math.floor(min + Math.random() * (max - min + 1));
exports.generateRandomInt = generateRandomInt;
/**
 * Compute Poseidon hash of inputs array
 * @param inputs
 * @returns
 */
const poseidon = (inputs) => {
    return poseidonRaw.F.toObject(poseidonRaw(inputs));
};
exports.poseidon = poseidon;
/**
 * Pad array with a given element up to a given length
 * @param arr
 * @param numElements
 * @param element
 * @returns
 */
const padArray = (arr, numElements, element) => {
    for (let i = arr.length; i < numElements; i += 1) {
        arr.push(element);
    }
    return arr;
};
exports.padArray = padArray;
/**
 * Generate new BabyJubJub key pair
 * @returns
 */
const generateKeypair = () => {
    const privKeyHex = (0, crypto_1.randomBytes)(31).toString("hex");
    const pubKey = eddsa.prv2pub(Buffer.from(privKeyHex, "hex"));
    const pubKeyX = eddsa.babyJub.F.toObject(pubKey[0]);
    const pubKeyY = eddsa.babyJub.F.toObject(pubKey[1]);
    return { privKeyHex, pubKey, pubKeyBigInt: [pubKeyX, pubKeyY] };
};
exports.generateKeypair = generateKeypair;
/**
 * Generate new note object
 * @param amount
 * @param token
 * @param sharedSecret
 * @param babyJubPubKey
 * @returns
 */
const generateNote = (amount, token = BigInt(0), sharedSecret = (0, exports.generateRandomBigInt)()) => {
    const generatedKeys = (0, exports.generateKeypair)();
    const noteData = {
        owner: {
            ownerBabyJub: generatedKeys.pubKeyBigInt,
            sharedSecret,
        },
        token: token || BigInt(0),
        amount,
    };
    return {
        ...noteData,
        privateKeypair: () => generatedKeys,
        serialize: () => noteData,
        id: () => {
            const ownerHash = (0, exports.poseidon)([
                noteData.owner.ownerBabyJub[0],
                noteData.owner.ownerBabyJub[1],
                noteData.owner.sharedSecret,
            ]);
            return (0, exports.poseidon)([ownerHash, amount, token]);
        },
        asOutput: () => {
            const ownerHash = (0, exports.poseidon)([
                noteData.owner.ownerBabyJub[0],
                noteData.owner.ownerBabyJub[1],
                noteData.owner.sharedSecret,
            ]);
            return {
                ownerHash,
                amount,
                token,
            };
        },
        isDecoy: () => {
            return false;
        },
    };
};
exports.generateNote = generateNote;
/**
 * Generate empty SMT tree
 * @returns
 */
const generateSMTTree = async (maxDepth) => {
    const tree = await (0, circomlibjs_2.newMemEmptyTrie)();
    // await tree.insert(BigInt(33273327), BigInt(3327))
    return {
        tree,
        insert: async (item) => await tree.insert(tree.F.e(item), tree.F.e(item)),
        root: () => tree.F.toObject(tree.root),
        cast: (item) => tree.F.toObject(tree.F.e(item)),
        generateNonInclusionProof: async (item) => {
            const res = await tree.find(item);
            return {
                raw: {
                    notFoundKey: res.notFoundKey
                        ? tree.F.toObject(res.notFoundKey)
                        : null,
                    notFoundValue: res.notFoundKey
                        ? tree.F.toObject(res.notFoundValue)
                        : null,
                    isOld0: res.isOld0,
                },
                proof: {
                    siblings: (0, exports.padArray)(res.siblings.map((sib) => tree.F.toObject(sib)), maxDepth, BigInt(0)),
                    key: tree.F.toObject(res.notFoundKey),
                    value: tree.F.toObject(res.notFoundValue),
                    isOld0: res.isOld0 ? BigInt(1) : BigInt(0),
                },
            };
        },
        generateInclusionProof: async (item) => {
            const res = await tree.find(item);
            return {
                raw: {
                    notFoundKey: res.notFoundKey
                        ? tree.F.toObject(res.notFoundKey)
                        : null,
                    notFoundValue: res.notFoundKey
                        ? tree.F.toObject(res.notFoundValue)
                        : null,
                    isOld0: res.isOld0,
                },
                proof: {
                    siblings: (0, exports.padArray)(res.siblings.map((sib) => tree.F.toObject(sib)), maxDepth, BigInt(0)),
                },
            };
        },
    };
};
exports.generateSMTTree = generateSMTTree;
const sign = (msg, privKeyHex) => {
    const privKey = Buffer.from(privKeyHex, "hex");
    const msgBuffer = eddsa.babyJub.F.e(msg);
    const signature = eddsa.signPoseidon(privKey, msgBuffer);
    const pSignature = eddsa.packSignature(signature);
    const uSignature = eddsa.unpackSignature(pSignature);
    //// Degug only!
    // if (eddsa.verifyPoseidon(msgBuffer, uSignature, pubKey)) {
    //   console.log('Valid signature!');
    // } else {
    //   console.log('Invalid signature');
    // }
    return {
        R8: [
            eddsa.babyJub.F.toObject(uSignature.R8[0]),
            eddsa.babyJub.F.toObject(uSignature.R8[1]),
        ],
        S: BigInt(uSignature.S.toString()),
    };
};
exports.sign = sign;
const generateAggregation = (maxInputs = 10, maxOutputs = 2, maxAmount = 100, feePerThousand = 1, setMaxValues = false) => {
    const inputKeypair = (0, exports.generateKeypair)();
    const inputNotes = [];
    const numInputs = setMaxValues
        ? maxInputs
        : (0, exports.generateRandomInt)(1, maxInputs);
    let inputSum = BigInt(0);
    // Generate input notes
    for (let i = 0; i < numInputs; i += 1) {
        const amount = maxAmount === 0
            ? BigInt(0)
            : BigInt((0, exports.generateRandomInt)(1, maxAmount));
        inputSum += amount;
        const inputNote = (0, exports.generateNote)(amount, BigInt(1), (0, exports.generateRandomBigInt)());
        inputNotes.push(inputNote);
    }
    // Pad input notes array
    for (let i = numInputs; i < maxInputs; i += 1) {
        const inputNote = (0, exports.generateNote)(BigInt(0), BigInt(1), (0, exports.generateRandomBigInt)());
        inputNotes.push(inputNote);
    }
    // Generate output notes
    const outputNotes = [];
    const numOutputs = setMaxValues
        ? maxOutputs
        : (0, exports.generateRandomInt)(1, maxOutputs);
    // Take fee from the input sum
    const feeAmount = BigInt(Math.floor(Number(inputSum) / Math.floor(1000 / feePerThousand)));
    let remainingOutputs = inputSum - feeAmount;
    for (let i = 0; i < numOutputs; i += 1) {
        let amount;
        if (i === numOutputs - 1) {
            amount = remainingOutputs;
        }
        else {
            amount = BigInt((0, exports.generateRandomInt)(1, Number(remainingOutputs)));
        }
        remainingOutputs -= amount;
        const outputNote = (0, exports.generateNote)(amount, BigInt(1), (0, exports.generateRandomBigInt)());
        outputNotes.push(outputNote);
    }
    // Pad output notes array
    for (let i = numOutputs; i < maxOutputs; i += 1) {
        const outputNote = (0, exports.generateNote)(BigInt(0), BigInt(0), (0, exports.generateRandomBigInt)());
        outputNotes.push(outputNote);
    }
    const ephemeralKeys = [];
    for (let _i = 0; _i < maxInputs; _i += 1) {
        ephemeralKeys.push((0, exports.generateRandomBigInt)());
    }
    // Generate and sign output hash
    const outputHash = (0, exports.poseidon)(outputNotes.map((note) => note.id()));
    const ephemeralKeysHash = (0, exports.poseidon)(ephemeralKeys);
    const outputAndEphemeralKeysHash = (0, exports.poseidon)([
        outputHash,
        ephemeralKeysHash,
    ]);
    const signatures = [];
    for (let i = 0; i < maxInputs; i += 1) {
        signatures.push((0, exports.sign)(outputAndEphemeralKeysHash, inputKeypair.privKeyHex));
    }
    return {
        inputNotes,
        outputNotes,
        signatures,
        feeAmount,
        ephemeralKeys,
    };
};
exports.generateAggregation = generateAggregation;
/**
 * Generate dummy aggregation skipped by circuit verifications
 * @param maxInputs
 * @param maxOutputs
 * @returns
 */
const generateDummyAggregation = (maxInputs = 10, maxOutputs = 2, feePerThousand = 1) => (0, exports.generateAggregation)(maxInputs, maxOutputs, 0, feePerThousand, true);
exports.generateDummyAggregation = generateDummyAggregation;
/**
 * Generate note nullifier
 * @param inputNote
 * @returns
 */
const generateNullifier = (inputNote) => (0, exports.poseidon)([...inputNote.owner.ownerBabyJub, inputNote.owner.sharedSecret]);
exports.generateNullifier = generateNullifier;
/**
 * Generate set of aggregations with circuit inputs
 * @param maxAggregations
 * @returns
 */
const generateAggregationSet = async (maxAggregations, maxInputs, maxOutputs, feePubKey, feeSecret, treeDepth = 20, setMaxValues = false, feePerThousand = 1) => {
    const numAggregations = setMaxValues
        ? maxInputs
        : (0, exports.generateRandomInt)(1, maxAggregations);
    const aggregations = [];
    const notesTree = await (0, exports.generateSMTTree)(treeDepth);
    const nullifiersTree = await (0, exports.generateSMTTree)(treeDepth);
    const nullifiers = [];
    const inputNotes = [];
    const outputNotes = [];
    let totalFee = BigInt(0);
    const ephemeralKeys = [];
    // Generate aggregations
    for (let i = 0; i < numAggregations; i += 1) {
        const aggregation = (0, exports.generateAggregation)(maxInputs, maxOutputs, 1000000, feePerThousand, setMaxValues);
        ephemeralKeys.push(...aggregation.ephemeralKeys);
        // Accumulate fee
        totalFee += aggregation.feeAmount;
        // Insert notes into tree
        for (const note of aggregation.inputNotes) {
            // Store input notes
            inputNotes.push(note);
            await notesTree.insert(note.id());
            const inputNullifier = (0, exports.generateNullifier)(note);
            // Store nullifier
            nullifiers.push(inputNullifier);
        }
        // Store output notes
        for (const note of aggregation.outputNotes) {
            outputNotes.push(note);
        }
        aggregations.push(aggregation);
    }
    // Pad aggregations array with dummy aggregations
    for (let i = numAggregations; i < maxAggregations; i += 1) {
        const aggregation = (0, exports.generateDummyAggregation)(maxInputs, maxOutputs);
        ephemeralKeys.push(...aggregation.ephemeralKeys);
        // Insert notes into tree
        for (const note of aggregation.inputNotes) {
            // Store input notes
            inputNotes.push(note);
            const inputNullifier = (0, exports.generateNullifier)(note);
            // Store nullifier
            nullifiers.push(inputNullifier);
            await notesTree.insert(note.id());
        }
        // Store output notes
        for (const note of aggregation.outputNotes) {
            outputNotes.push(note);
        }
        aggregations.push(aggregation);
    }
    // Init tree values
    const oldNotesRoot = notesTree.root();
    const oldNullifiersRoot = nullifiersTree.root();
    // Process input note inclusion proofs and nullifier non-inclusion proofs
    // aggregation > outputNote > siblings
    const inputNoteInclusionProofs = [];
    const nullifierNonInclusionProofs = [];
    for (let i = 0; i < maxAggregations; i += 1) {
        inputNoteInclusionProofs[i] = [];
        nullifierNonInclusionProofs[i] = [];
        for (const note of aggregations[i].inputNotes) {
            inputNoteInclusionProofs[i].push((await notesTree.generateInclusionProof(note.id())).proof);
            // Insert nullifiers into tree
            const nullifier = (0, exports.generateNullifier)(note);
            // Process nullifier non-inclusion proof
            nullifierNonInclusionProofs[i].push((await nullifiersTree.generateNonInclusionProof(nullifier))
                .proof);
            await nullifiersTree.insert(nullifier);
        }
    }
    // aggregation > outputNote > siblings
    const outputNoteNonInclusionProofs = [];
    // Insert output notes into tree
    for (let i = 0; i < maxAggregations; i += 1) {
        outputNoteNonInclusionProofs[i] = [];
        for (const note of aggregations[i].outputNotes) {
            // Process output note inclusion proofs
            outputNoteNonInclusionProofs[i].push((await notesTree.generateNonInclusionProof(note.id())).proof);
            await notesTree.insert(note.id());
        }
    }
    // Generate fee note
    const feeNote = (0, exports.generateNote)(totalFee, BigInt(0), feeSecret);
    const feeNoteNonInclusionProof = (await notesTree.generateNonInclusionProof(feeNote.id())).proof;
    // Insert fee note into the three
    await notesTree.insert(feeNote.id());
    // Get new tree rots
    const newNullifiersRoot = nullifiersTree.root();
    const newNotesRoot = notesTree.root();
    return {
        aggregations: aggregations.map((agg, i) => ({
            inputNotes: agg.inputNotes.map((note) => note.serialize()),
            outputNotes: agg.outputNotes.map((note) => note.asOutput()),
            nullifierNonInclusionProof: nullifierNonInclusionProofs[i], // nullifierInclusionSiblings[treeDepth];
            inputNoteInclusionProof: inputNoteInclusionProofs[i], // inputNoteInclusionSiblings[treeDepth];
            outputNoteNonInclusionProof: outputNoteNonInclusionProofs[i], // outputNoteInclusionSiblings[treeDepth];
            outputNoteSignatures: agg.signatures, // Signature() outputNoteSignatures[maxInputNotes][maxOutputNotes];
        })),
        oldNotesRoot,
        oldNullifiersRoot,
        newNullifiersRoot,
        newNotesRoot,
        nullifiers,
        ephemeralKeys: ephemeralKeys.flat(),
        feeNote: feeNote.asOutput(),
        feeNoteNonInclusionProof,
        outputNoteIds: [
            ...outputNotes.map((note) => note.id()),
            feeNote.id(),
        ].map((item) => notesTree.cast(item)),
        nullifiersHash: (0, exports.sha256BigInt)(nullifiers),
    };
};
exports.generateAggregationSet = generateAggregationSet;
const generateDecoyNote = (amount = BigInt(0), token = BigInt(1), sharedSecret = (0, exports.generateRandomBigInt)()) => {
    const keypair = (0, exports.generateKeypair)();
    const note = (0, exports.generateNote)(amount, token, sharedSecret);
    note.isDecoy = () => false;
    return note;
};
exports.generateDecoyNote = generateDecoyNote;
