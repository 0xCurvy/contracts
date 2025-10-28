// We define a module in the test file here, but you can also `import` it.

import { network } from "hardhat";
import { expect, test } from "vitest";
import CurvyVaultModule from "../ignition/modules/CurvyVault";

test("should set the start count to 0 by default", async () => {
  const { ignition } = await network.connect();
  const { proxy, curvyVaultV1, curvyVault } = await ignition.deploy(CurvyVaultModule);

  expect(curvyVaultV1).toBeDefined();
  expect(proxy).toBeDefined();

  const numberOfTokens = await curvyVault.read.getNumberOfTokens();
  expect(numberOfTokens).toBe(1n);

  const owner = await curvyVault.read.owner();
  expect(owner.toLowerCase()).toBe("0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266");
});
