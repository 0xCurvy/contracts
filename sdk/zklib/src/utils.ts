import { buildPoseidon, buildEddsa } from "circomlibjs";
import { randomBytes } from "crypto";
import { Keypair, Note, NoteData, RawAggregation, Signature } from "./types";
import { newMemEmptyTrie } from "circomlibjs";
import { createHash } from "crypto";

let poseidonRaw;
let eddsa;
export const init = async () => {
    poseidonRaw = await buildPoseidon();
    eddsa = await buildEddsa();
};

// Monkey patching BigInt toJSON method for it to work in JSON.stringify
(BigInt.prototype as any).toJSON = function () {
    return this.toString();
};

/**
 * Stringify json with bigints
 * @param obj
 * @returns
 */
export const serializeJson = (obj: any) => {
    return JSON.stringify(
        obj,
        (_, v) => (typeof v === "bigint" ? v.toString() : v),
        2
    );
};

export const sha256BigInt = (inputs: bigint[]) => {
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

    return BigInt("0x" + createHash("sha256").update(buffer).digest("hex"));
};

export const flattenNonInclusionProofBus = (proof: any) => {
    return [...proof.siblings, proof.isOld0, proof.key, proof.value];
};

export const flattenInclusionProofBus = (proof: any) => {
    return [...proof.siblings];
};

export const flattenNoteBus = (note: any) => {
    return [
        ...note.owner.ownerBabyJub,
        note.owner.sharedSecret,
        note.amount,
        note.token,
    ];
};

export const flattenOutputNoteBus = (note: any) => {
    return [note.ownerHash, note.amount, note.token];
};

export const flattenSignatureBus = (sig: any) => {
    return [sig.S, ...sig.R8];
};

/**
 * Flatten input busses for insertion verification circuit
 * @param obj
 * @returns
 */
export const flattenVerifyInsertionInputs = (obj: any) => {
    return {
        ...obj,
        notes: obj.notes.map((note: any) => flattenOutputNoteBus(note)).flat(),
        noteNonInclusionProofs: obj.noteNonInclusionProofs.map((proof: any) =>
            flattenNonInclusionProofBus(proof)
        ),
    };
};

export const flattenAggregationBus = (agg: any) => {
    return [
        ...agg.inputNotes.map((note: any) => flattenNoteBus(note)).flat(),
        ...agg.outputNotes
            .map((note: any) => flattenOutputNoteBus(note))
            .flat(),
        ...agg.nullifierNonInclusionProof
            .map((proof: any) => flattenNonInclusionProofBus(proof))
            .flat(), // nullifierInclusionSiblings[treeDepth];
        ...agg.inputNoteInclusionProof
            .map((proof: any) => flattenInclusionProofBus(proof))
            .flat(), // inputNoteInclusionSiblings[treeDepth];
        ...agg.outputNoteNonInclusionProof
            .map((proof: any) => flattenNonInclusionProofBus(proof))
            .flat(), // outputNoteInclusionSiblings[treeDepth];
        ...agg.outputNoteSignatures
            .map((sig: any) => flattenSignatureBus(sig))
            .flat(), // Signature() outputNoteSignatures[maxInputNotes][maxOutputNotes];
    ];
};

/**
 * Flatten input busses for insertion aggregation circuit
 * @param obj
 * @returns
 */
export const flattenVerifyAggregationInputs = (obj: any) => {
    const allInputs = {
        ...obj,
        aggregations: obj.aggregations
            .map((agg: any) => flattenAggregationBus(agg))
            .flat(),
        ephemeralKeys: obj.ephemeralKeys,
        feeNote: flattenOutputNoteBus(obj.feeNote),
        feeNoteNonInclusionProof: flattenNonInclusionProofBus(
            obj.feeNoteNonInclusionProof
        ),
        nullifiersHash: obj.nullifiersHash,
    };

    // Removing output signals
    delete allInputs.nullifiers;
    delete allInputs.outputNoteIds;
    return allInputs;
};

export const flattenWithdrawBus = (bus: any, treeDepth: number) => [
    // 1) inputNotes
    ...bus.inputNotes.map((n: any) => flattenNoteBus(n)).flat(),

    // 2) signatures
    ...bus.signatures.map((s: any) => flattenSignatureBus(s)).flat(),

    // 3) noteInclusionProofs  → just siblings
    ...bus.noteInclusionProofs
        .map((p: any) => flattenInclusionProofBus(p))
        .flat(), // nInputs * treeDepth

    // 4) nullifierNonInclusionProofs → siblings + isOld0 + key + value
    ...bus.nullifierNonInclusionProofs
        .map((p: any) => flattenNonInclusionProofBus(p))
        .flat(), // nInputs * (treeDepth + 3)
];

/**
 * Flatten input busses for VerifyWithdraw circuit
 * @param obj
 * @returns
 */
export const flattenVerifyWithdrawInputs = (
    obj: {
        w: any;
        notesTreeRoot: bigint;
        oldNullifiersRoot: bigint;
        destinationAddress: bigint;
        withdrawFlag: bigint;
    },
    treeDepth: number
) => ({
    w: flattenWithdrawBus(obj.w, treeDepth),
    notesTreeRoot: obj.notesTreeRoot,
    oldNullifiersRoot: obj.oldNullifiersRoot,
    destinationAddress: obj.destinationAddress,
    withdrawFlag: obj.withdrawFlag,
});

/**
 * Generate random bigint value
 * @param bytes
 * @returns
 */
export const generateRandomBigInt = (bytes: number = 31) =>
    BigInt("0x" + randomBytes(bytes).toString("hex"));

/**
 * Generate random integer in range [min, max]
 * @param min
 * @param max
 * @returns
 */
export const generateRandomInt = (min: number, max: number) =>
    Math.floor(min + Math.random() * (max - min + 1));

/**
 * Compute Poseidon hash of inputs array
 * @param inputs
 * @returns
 */
export const poseidon = (inputs: bigint[]): bigint => {
    return poseidonRaw.F.toObject(poseidonRaw(inputs));
};

/**
 * Pad array with a given element up to a given length
 * @param arr
 * @param numElements
 * @param element
 * @returns
 */
export const padArray = (
    arr: any[],
    numElements: number,
    element: any
): any[] => {
    for (let i = arr.length; i < numElements; i += 1) {
        arr.push(element);
    }
    return arr;
};

/**
 * Generate new BabyJubJub key pair
 * @returns
 */
export const generateKeypair = (): Keypair => {
    const privKeyHex = randomBytes(31).toString("hex");
    const pubKey = eddsa.prv2pub(Buffer.from(privKeyHex, "hex"));
    const pubKeyX = eddsa.babyJub.F.toObject(pubKey[0]);
    const pubKeyY = eddsa.babyJub.F.toObject(pubKey[1]);

    return { privKeyHex, pubKey, pubKeyBigInt: [pubKeyX, pubKeyY] };
};

/**
 * Generate new note object
 * @param amount
 * @param token
 * @param sharedSecret
 * @param babyJubPubKey
 * @returns
 */
export const generateNote = (
    amount: bigint,
    token: bigint = BigInt(0),
    sharedSecret: bigint = generateRandomBigInt()
): Note => {
    const generatedKeys = generateKeypair();
    const noteData: NoteData = {
        owner: {
            ownerBabyJub: generatedKeys.pubKeyBigInt,
            sharedSecret,
        },
        token: token || BigInt(0),
        amount,
    };

    return {
        ...noteData,
        privateKeypair: (): Keypair => generatedKeys,
        serialize: (): any => noteData,
        id: (): bigint => {
            const ownerHash = poseidon([
                noteData.owner.ownerBabyJub[0]!,
                noteData.owner.ownerBabyJub[1]!,
                noteData.owner.sharedSecret,
            ]);

            return poseidon([ownerHash, amount, token]);
        },
        asOutput: () => {
            const ownerHash = poseidon([
                noteData.owner.ownerBabyJub[0]!,
                noteData.owner.ownerBabyJub[1]!,
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

/**
 * Generate empty SMT tree
 * @returns
 */
export const generateSMTTree = async (maxDepth: number) => {
    const tree = await newMemEmptyTrie();
    // await tree.insert(BigInt(33273327), BigInt(3327))
    return {
        tree,
        insert: async (item: bigint) =>
            await tree.insert(tree.F.e(item), tree.F.e(item)),
        root: () => tree.F.toObject(tree.root),
        cast: (item: bigint) => tree.F.toObject(tree.F.e(item)),
        generateNonInclusionProof: async (item: bigint) => {
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
                    siblings: padArray(
                        res.siblings.map((sib: any) => tree.F.toObject(sib)),
                        maxDepth,
                        BigInt(0)
                    ) as bigint[],
                    key: tree.F.toObject(res.notFoundKey),
                    value: tree.F.toObject(res.notFoundValue),
                    isOld0: res.isOld0 ? BigInt(1) : BigInt(0),
                },
            };
        },
        generateInclusionProof: async (item: bigint) => {
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
                    siblings: padArray(
                        res.siblings.map((sib: any) => tree.F.toObject(sib)),
                        maxDepth,
                        BigInt(0)
                    ) as bigint[],
                },
            };
        },
    };
};

export const sign = (msg: bigint, privKeyHex: string): Signature => {
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

export const generateAggregation = (
    maxInputs: number = 10,
    maxOutputs: number = 2,
    maxAmount: number = 100,
    feePerThousand: number = 1,
    setMaxValues: boolean = false
): RawAggregation => {
    const inputKeypair = generateKeypair();

    const inputNotes: Note[] = [];
    const numInputs = setMaxValues
        ? maxInputs
        : generateRandomInt(1, maxInputs);

    let inputSum: bigint = BigInt(0);

    // Generate input notes
    for (let i = 0; i < numInputs; i += 1) {
        const amount =
            maxAmount === 0
                ? BigInt(0)
                : BigInt(generateRandomInt(1, maxAmount));
        inputSum += amount;

        const inputNote: Note = generateNote(
            amount,
            BigInt(1),
            generateRandomBigInt()
        );

        inputNotes.push(inputNote);
    }

    // Pad input notes array
    for (let i = numInputs; i < maxInputs; i += 1) {
        const inputNote: Note = generateNote(
            BigInt(0),
            BigInt(1),
            generateRandomBigInt()
        );

        inputNotes.push(inputNote);
    }

    // Generate output notes
    const outputNotes: Note[] = [];
    const numOutputs = setMaxValues
        ? maxOutputs
        : generateRandomInt(1, maxOutputs);

    // Take fee from the input sum
    const feeAmount: bigint = BigInt(
        Math.floor(Number(inputSum) / Math.floor(1000 / feePerThousand))
    );
    let remainingOutputs: bigint = inputSum - feeAmount;

    for (let i = 0; i < numOutputs; i += 1) {
        let amount: bigint;

        if (i === numOutputs - 1) {
            amount = remainingOutputs;
        } else {
            amount = BigInt(generateRandomInt(1, Number(remainingOutputs)));
        }

        remainingOutputs -= amount;

        const outputNote: Note = generateNote(
            amount,
            BigInt(1),
            generateRandomBigInt()
        );

        outputNotes.push(outputNote);
    }

    // Pad output notes array
    for (let i = numOutputs; i < maxOutputs; i += 1) {
        const outputNote: Note = generateNote(
            BigInt(0),
            BigInt(0),
            generateRandomBigInt()
        );

        outputNotes.push(outputNote);
    }

    const ephemeralKeys: bigint[] = [];
    for (let _i = 0; _i < maxInputs; _i += 1) {
        ephemeralKeys.push(generateRandomBigInt());
    }

    // Generate and sign output hash
    const outputHash = poseidon(outputNotes.map((note) => note.id()));
    const ephemeralKeysHash = poseidon(ephemeralKeys);
    const outputAndEphemeralKeysHash = poseidon([
        outputHash,
        ephemeralKeysHash,
    ]);
    const signatures: Signature[] = [];

    for (let i = 0; i < maxInputs; i += 1) {
        signatures.push(
            sign(outputAndEphemeralKeysHash, inputKeypair.privKeyHex)
        );
    }

    return {
        inputNotes,
        outputNotes,
        signatures,
        feeAmount,
        ephemeralKeys,
    };
};

/**
 * Generate dummy aggregation skipped by circuit verifications
 * @param maxInputs
 * @param maxOutputs
 * @returns
 */
export const generateDummyAggregation = (
    maxInputs: number = 10,
    maxOutputs: number = 2,
    feePerThousand: number = 1
) => generateAggregation(maxInputs, maxOutputs, 0, feePerThousand, true);

/**
 * Generate note nullifier
 * @param inputNote
 * @returns
 */
export const generateNullifier = (inputNote: Note) =>
    poseidon([...inputNote.owner.ownerBabyJub, inputNote.owner.sharedSecret]);

/**
 * Generate set of aggregations with circuit inputs
 * @param maxAggregations
 * @returns
 */
export const generateAggregationSet = async (
    maxAggregations: number,
    maxInputs: number,
    maxOutputs: number,
    feePubKey: bigint[],
    feeSecret: bigint,
    treeDepth: number = 20,
    setMaxValues: boolean = false,
    feePerThousand: number = 1
) => {
    const numAggregations = setMaxValues
        ? maxInputs
        : generateRandomInt(1, maxAggregations);
    const aggregations: RawAggregation[] = [];

    const notesTree = await generateSMTTree(treeDepth);
    const nullifiersTree = await generateSMTTree(treeDepth);

    const nullifiers: bigint[] = [];
    const inputNotes: Note[] = [];
    const outputNotes: Note[] = [];

    let totalFee: bigint = BigInt(0);

    const ephemeralKeys: bigint[] = [];

    // Generate aggregations
    for (let i = 0; i < numAggregations; i += 1) {
        const aggregation = generateAggregation(
            maxInputs,
            maxOutputs,
            1000000,
            feePerThousand,
            setMaxValues
        );

        ephemeralKeys.push(...aggregation.ephemeralKeys);

        // Accumulate fee
        totalFee += aggregation.feeAmount;

        // Insert notes into tree
        for (const note of aggregation.inputNotes) {
            // Store input notes
            inputNotes.push(note);

            await notesTree.insert(note.id());
            const inputNullifier = generateNullifier(note);

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
        const aggregation = generateDummyAggregation(maxInputs, maxOutputs);

        ephemeralKeys.push(...aggregation.ephemeralKeys);

        // Insert notes into tree
        for (const note of aggregation.inputNotes) {
            // Store input notes
            inputNotes.push(note);

            const inputNullifier = generateNullifier(note);

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
    const oldNotesRoot: bigint = notesTree.root();
    const oldNullifiersRoot: bigint = nullifiersTree.root();

    // Process input note inclusion proofs and nullifier non-inclusion proofs
    // aggregation > outputNote > siblings
    const inputNoteInclusionProofs: any[][] = [];
    const nullifierNonInclusionProofs: any[][] = [];
    for (let i = 0; i < maxAggregations; i += 1) {
        inputNoteInclusionProofs[i] = [];
        nullifierNonInclusionProofs[i] = [];

        for (const note of aggregations[i]!.inputNotes) {
            inputNoteInclusionProofs[i]!.push(
                (await notesTree.generateInclusionProof(note.id())).proof
            );

            // Insert nullifiers into tree
            const nullifier = generateNullifier(note);

            // Process nullifier non-inclusion proof
            nullifierNonInclusionProofs[i]!.push(
                (await nullifiersTree.generateNonInclusionProof(nullifier))
                    .proof
            );
            await nullifiersTree.insert(nullifier);
        }
    }

    // aggregation > outputNote > siblings
    const outputNoteNonInclusionProofs: any[][] = [];

    // Insert output notes into tree
    for (let i = 0; i < maxAggregations; i += 1) {
        outputNoteNonInclusionProofs[i] = [];
        for (const note of aggregations[i]!.outputNotes) {
            // Process output note inclusion proofs
            outputNoteNonInclusionProofs[i]!.push(
                (await notesTree.generateNonInclusionProof(note.id())).proof
            );
            await notesTree.insert(note.id());
        }
    }

    // Generate fee note
    const feeNote = generateNote(totalFee, BigInt(0), feeSecret);
    const feeNoteNonInclusionProof = (
        await notesTree.generateNonInclusionProof(feeNote.id())
    ).proof;

    // Insert fee note into the three
    await notesTree.insert(feeNote.id());

    // Get new tree rots
    const newNullifiersRoot: bigint = nullifiersTree.root();
    const newNotesRoot: bigint = notesTree.root();

    return {
        aggregations: aggregations.map((agg, i: number) => ({
            inputNotes: agg.inputNotes.map((note: Note) => note.serialize()),
            outputNotes: agg.outputNotes.map((note: Note) => note.asOutput()),
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
        nullifiersHash: sha256BigInt(nullifiers),
    };
};

export const generateDecoyNote = (
    amount: bigint = BigInt(0),
    token: bigint = BigInt(1),
    sharedSecret: bigint = generateRandomBigInt()
): Note => {
    const keypair = generateKeypair();
    const note = generateNote(amount, token, sharedSecret);
    note.isDecoy = () => false;
    return note;
};
