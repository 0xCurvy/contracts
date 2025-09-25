import { getContracts } from '../contracts';
import { beforeAll, expect, test } from "vitest";

const OPERATOR_ADDRESS = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';

beforeAll(async () => {
    const { curvyAggregator, metaErc20Wrapper } = getContracts();
    expect(curvyAggregator).toBeDefined();
    expect(metaErc20Wrapper).toBeDefined();
    await metaErc20Wrapper.write.setAggregatorContractAddress([curvyAggregator.address]);
});

test('should be able to get the curvy aggregator', async () => {
    const { curvyAggregator, metaErc20Wrapper } = getContracts();
    expect(curvyAggregator).toBeDefined();
    const noteTree = await curvyAggregator.read.noteTree();
    expect(noteTree).toBeDefined();
    const operator = await curvyAggregator.read.operator();
    expect(operator).toBeDefined();
    expect(operator).to.not.be.equal('0x0000000000000000000000000000000000000000');
});

test('should deposit ETH as a note to the curvy aggregator', async () => {
    const { curvyAggregator, metaErc20Wrapper } = getContracts();
    expect(curvyAggregator).toBeDefined();
    expect(metaErc20Wrapper).toBeDefined();

    await metaErc20Wrapper.write.deposit([
        '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
        OPERATOR_ADDRESS,
        '1000',
    ], {
        value: "1000",
    });

    const balance = await metaErc20Wrapper.read.balanceOf([
        OPERATOR_ADDRESS, 
        1 // ETH ID
    ]);
    expect(balance).toBeDefined();
    expect(balance).to.be.greaterThan(0);

    console.log("Balance: ", balance);

    const res = await curvyAggregator.write.depositNote([
        OPERATOR_ADDRESS,
        {
            ownerHash: '0x0000000000000000000000000000000000000000000000000000000000000001',
            token: '1', // ETH_ID
            amount: '1000',
        }
    ]);

    expect(res).toBeDefined();
})