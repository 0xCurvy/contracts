import { getContracts } from '../contracts';
import { expect, test } from "vitest";

test('should be able to get the curvy aggregator', async () => {
    const { curvyAggregator } = getContracts();
    expect(curvyAggregator).toBeDefined();
    const noteTree = await curvyAggregator.read.noteTree();
    expect(noteTree).toBeDefined();
    console.log(noteTree);
    const operator = await curvyAggregator.read.operator();
    expect(operator).toBeDefined();

    // TODO: Fix this test
    // expect(operator).to.not.be.equal('0x0000000000000000000000000000000000000000');
    // console.log(operator);
})