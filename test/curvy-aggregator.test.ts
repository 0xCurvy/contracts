import { getContracts } from '../contracts';
import { beforeAll, expect, test } from "vitest";
import { encodePacked, sha256 } from 'viem'
import { poseidon3 } from 'poseidon-lite';

type Note = {
    ownerHash: string;
    token: string;
    amount: string;
}

const OPERATOR_ADDRESS = "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266";
const SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617n;

beforeAll(async () => {
    const { curvyAggregator, metaERC20Wrapper } = getContracts();
    expect(curvyAggregator).toBeDefined();
    expect(metaERC20Wrapper).toBeDefined();

    await metaERC20Wrapper.write.setAggregatorContractAddress([
        curvyAggregator.address,
    ]);

    await metaERC20Wrapper.write.deposit([
        "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
        OPERATOR_ADDRESS,
        "1000"
    ], {
        value: 1000n
    });
    
    const balance = await metaERC20Wrapper.read.balanceOf([
        OPERATOR_ADDRESS,
        "1",
    ]);

    expect(balance).toBeDefined();
    expect(balance).toBeGreaterThan(0n);
})

test('should be able to get the curvy aggregator', async () => {
    const { curvyAggregator, metaERC20Wrapper } = getContracts();
    expect(curvyAggregator).toBeDefined();
    expect(metaERC20Wrapper).toBeDefined();
    const noteTree = await curvyAggregator.read.noteTree();
    expect(noteTree).toBeDefined();
    const operator = await curvyAggregator.read.operator();
    expect(operator).toBeDefined();
    expect(operator).to.not.be.equal('0x0000000000000000000000000000000000000000');
})

test('should be able to deposit notes', async () => {
    const { curvyAggregator } = getContracts();
    expect(curvyAggregator).toBeDefined();

    const fromAddresses = OPERATOR_ADDRESS;

    const note1: Note = {
        ownerHash: "122345",
        token: "1",
        amount: "100"
    };

    const note2: Note = {
        ownerHash: "122345",
        token: "1",
        amount: "50"
    };

    const tx1 = await curvyAggregator.write.depositNote([fromAddresses, note1]);

    console.log("TX1:", tx1);

    const tx2 = await curvyAggregator.write.depositNote([fromAddresses, note2]);

    expect(tx2).toBeDefined();
})

test("commit deposit batch", async () => {
    const { curvyAggregator } = getContracts();
    expect(curvyAggregator).toBeDefined();

    const note1: Note = {
        ownerHash: "122345",
        token: "1",
        amount: "100"
    };

    const note2: Note = {
        ownerHash: "122345",
        token: "1",
        amount: "50"
    };

    const proof_a = ["0", "0"];
    const proof_b = [["0", "0"], ["0", "0"]];
    const proof_c = ["0", "0"];

    const noteIds = []
    noteIds.push(poseidon3([note1.ownerHash, note1.token, note1.amount]));
    noteIds.push(poseidon3([note2.ownerHash, note2.token, note2.amount]));

    const encodedNoteIds = encodePacked(["uint256[]"], [noteIds])

    const notesHash = BigInt(sha256(encodedNoteIds)) % SNARK_SCALAR_FIELD;

    const publicInputs = new Array(152).fill("0");
    publicInputs[149] = "0";
    publicInputs[150] = "123";
    publicInputs[151] = notesHash.toString();

    console.log(noteIds, proof_a, proof_b, proof_c, publicInputs);

    const tx = await curvyAggregator.write.commitDepositBatch([noteIds, proof_a, proof_b, proof_c, publicInputs]);

    expect(tx).toBeDefined();
})

test("commit aggregation batch", async () => {
    const { curvyAggregator } = getContracts();
    expect(curvyAggregator).toBeDefined();

    const proof_a = ["0", "0"];
    const proof_b = [["0", "0"], ["0", "0"]];
    const proof_c = ["0", "0"];

    const publicInputs = new Array(46).fill("0");
    publicInputs[21] = "0";
    publicInputs[22] = "111";
    publicInputs[23] = "123";
    publicInputs[24] = "456";

    const tx = await curvyAggregator.write.commitAggregationBatch([proof_a, proof_b, proof_c, publicInputs]);

    expect(tx).toBeDefined();
})