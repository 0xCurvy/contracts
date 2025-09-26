import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("CurvyInsertionVerifier", (m) => {
  const curvyInsertionVerifier = m.contract("CurvyInsertionVerifier");

  return { curvyInsertionVerifier };
});
