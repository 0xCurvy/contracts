export type NoteData = {
    owner: {
        ownerBabyJub: bigint[];
        sharedSecret: bigint;
    };
    amount: bigint;
    token: bigint;
};

export type OutputNoteData = {
    ownerHash: bigint;
    amount: bigint;
    token: bigint;
};

export type Note = {
    privateKeypair?: () => Keypair;
    serialize: () => NoteData;
    id: () => bigint;
    asOutput: () => OutputNoteData;
    isDecoy: () => boolean;
} & NoteData;

export type Keypair = {
    privKeyHex: string;
    pubKey: any;
    pubKeyBigInt: bigint[];
};

export type Signature = {
    S: bigint;
    R8: bigint[];
};

export type RawAggregation = {
    inputNotes: Note[];
    outputNotes: Note[];
    signatures: Signature[];
    feeAmount: bigint;
    ephemeralKeys: bigint[];
};

import { SMT } from "circomlibjs";

export type Proof = {
    pi_a: [string, string];
    pi_b: [[string, string], [string, string]];
    pi_c: [string, string];
    protocol: string;
    curve: string;
};

export type ProveResult = {
    proof: Proof;
    publicSignals: string[];
};

export type PoseidonHash = (inputs: bigint[]) => bigint;

export type CircuitConfig = {
    id: string;
    circuit: string;
    title: string;
    treeDepth: number;
    maxInputs: number;
    maxOutputs: number;
    maxAggregations: number;
    groupFee: number;
};

export type InputNoteData = {
    owner: {
        ownerBabyJub: bigint[];
        sharedSecret: bigint;
    };
    amount: bigint;
    token: bigint;
};

export type NonInclusionProofWrap = {
    raw: any;
    proof: {
        siblings: bigint[];
        key: bigint;
        value: bigint;
        isOld0: bigint;
    };
};

export type InclusionProofWrap = {
    raw: any;
    proof: {
        siblings: bigint[];
    };
};

export type SMTree = {
    tree: SMT;
    insert: (_: bigint) => Promise<void>;
    root: () => bigint;
    cast: (_: bigint) => BigInteger;
    find: (_: bigint) => any;
    generateNonInclusionProof: (_: bigint) => Promise<NonInclusionProofWrap>;
    generateInclusionProof: (_: bigint) => Promise<InclusionProofWrap>;
};

export type Aggregation = {
    inputNotes: Note[];
    outputNotes: Note[];
    signatures: Signature[];
    feeAmount: bigint;
    ephemeralKeys: bigint[];
};

export type DepositCircuitInputs = {
    oldNotesRoot: bigint;
    newNotesRoot: bigint;
    notes: OutputNoteData[];
    noteNonInclusionProofs: NonInclusionProofWrap["proof"][];
};

export type AggregationForCircuit = {
    inputNotes: InputNoteData[];
    outputNotes: OutputNoteData[];
    nullifierNonInclusionProofs: NonInclusionProofWrap["proof"][];
    inputNoteInclusionProofs: InclusionProofWrap["proof"][];
    outputNoteNonInclusionProofs: NonInclusionProofWrap["proof"][];
    outputNoteSignatures: Signature[];
};

export type AggregationCircuitInputs = {
    aggregations: AggregationForCircuit[];
    oldNotesRoot: bigint;
    oldNullifiersRoot: bigint;
    newNullifiersRoot: bigint;
    newNotesRoot: bigint;
    nullifiers: bigint[];
    feeNote: OutputNoteData;
    feeNoteNonInclusionProof: NonInclusionProofWrap["proof"];
    outputNoteIds: bigint[];
    ephemeralKeys: bigint[];
};

export type AggregationRequest = {
    id: string;
    isDummy: boolean;
    userId: string;
    ephemeralKeys: bigint[];
    inputNotesData: InputNoteData[];
    outputNotesData: OutputNoteData[];
    outputSignatures: Signature[];
    fee: number;
    aggregationGroupId: string;
};

export type WithdrawRequest = {
    id?: string;
    inputNotes: InputNoteData[];
    signatures: Signature[];
    destinationAddress: bigint;
};

export type WithdrawCircuitInputs = {
    inputNotes: InputNoteData[];
    signatures: Signature[];
    noteInclusionProofs: InclusionProofWrap["proof"][];
    nullifierNonInclusionProofs: NonInclusionProofWrap["proof"][];
    notesTreeRoot: bigint;
    oldNullifiersRoot: bigint;
    destinationAddress: bigint;
    withdrawFlag: bigint;
};
