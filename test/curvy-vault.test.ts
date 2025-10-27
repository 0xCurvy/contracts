// We define a module in the test file here, but you can also `import` it.

import { network } from "hardhat";
import { expect, test } from "vitest";
import CurvyVaultModule from "../ignition/modules/CurvyVault";

test("should set the start count to 0 by default", async () => {
  const { ignition, viem } = await network.connect();
  const { proxy, curvyVaultV1, curvyVault } = await ignition.deploy(CurvyVaultModule);

  expect(curvyVaultV1).toBeDefined();
  expect(proxy).toBeDefined();

  const numberOfTokens = await curvyVault.read.getNumberOfTokens();
  expect(numberOfTokens).toBe(1n);
});
