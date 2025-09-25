import { CurvySDK, Note } from "@0xcurvy/curvy-sdk";
const MAX_NOTES = 50;

const generateNoteDepositPayload = async (notes: any[]) => {
    const curvySDK = CurvySDK.init("local");
    // const notesTree = new NotesTree();
    // TODO: Insert notes into notesTree (skip 0 amounts),

    const note3 = new  Note({
        ownerHash: "122345",
        balance: {
            token: "1",
            amount: "3000"
        },
        deliveryTag: {
            ephemeralKey: "0",
            viewTag: "0"
        }
    });

    
    
    const noteDepositPayload = {
        oldNotesRoot: 0n,
        newNotesRoot: 0n, // TODO: Get updated notes root
        notes: [], // TODO: notes.map((note) => note.asOutput()),
        noteNonInclusionProofs: [], // TODO: Get note non inclusion proofs
        noteIds: [] // TODO: padArray(notes.map((note) => note.id()), MAX_NOTES, BigInt(0)),
    };

    return noteDepositPayload;
};

const generateNoteAggregationPayload = async () => {
    const noteAggregationPayload = {

    };

    return noteAggregationPayload;
};


const generateNoteWithdrawalPayload = async () => {
    const noteWithdrawalPayload = {

    };

    return noteWithdrawalPayload;
};