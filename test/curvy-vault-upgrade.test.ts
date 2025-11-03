// We define a module in the test file here, but you can also `import` it.
import { network } from "hardhat";
import { expect, test } from "vitest";
import CurvyVaultModule from "../ignition/modules/CurvyVault";
import CurvyVaultV2Module from "../ignition/modules/test/CurvyVaultV2Mock";

test("curvy vault upgrade", async () => {
  const { ignition } = await network.connect();

  const { implementation, proxy, curvyVault } = await ignition.deploy(CurvyVaultModule);

  expect(implementation).toBeDefined();
  expect(proxy).toBeDefined();
  expect(curvyVault).toBeDefined();

  const numberOfTokens = await curvyVault.read.getNumberOfTokens();
  expect(numberOfTokens).toBe(1n);

  const owner = await curvyVault.read.owner();
  expect(owner.toLowerCase()).toBe("0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266");

  const version = (await curvyVault.read.eip712Domain())[2];
  expect(version).toBe("1.0");

  // Do the upgrade
  const { curvyVault: newCurvyVault } = await ignition.deploy(CurvyVaultV2Module);

  const newVersion = (await newCurvyVault.read.eip712Domain())[2];
  expect(newVersion).toBe("2.0");

  // Try to read version from "old vault", it should also return 2.0 because of delegatecall
  const newVersionFromOldVault = (await curvyVault.read.eip712Domain())[2];
  expect(newVersionFromOldVault).toBe("2.0");
}, 5000000);
