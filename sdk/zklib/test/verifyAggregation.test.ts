import "should";
import {
  flattenVerifyAggregationInputs,
  generateAggregationSet,
  generateKeypair,
  generateRandomBigInt,
} from "../src/utils";
import { wasm as wasm_tester } from "circom_tester";
import path from "path";

const circuit = await wasm_tester(
  path.join(
    __dirname,
    "..",
    "circuits",
    "instances",
    "verifyAggregation_2_2_2.circom"
  )
);

describe("Note aggregation tests", () => {
  it("should aggregate two valid notes", async () => {
    const MAX_AGGREGATIONS: number = 2;
    const MAX_INPUTS: number = 2;
    const MAX_OUTPUTS: number = 2;
    const TREE_DEPTH = 20;

    const feeKeypair = generateKeypair();
    const feeSecret = generateRandomBigInt();

    const res = await generateAggregationSet(
      MAX_AGGREGATIONS,
      MAX_INPUTS,
      MAX_OUTPUTS,
      feeKeypair.pubKeyBigInt,
      feeSecret,
      TREE_DEPTH,
      true,
      1
    );

    const w = await circuit.calculateWitness(
      flattenVerifyAggregationInputs(res)
    );

    await circuit.checkConstraints(w, true);
  });
});
