import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("CurvyAggregator", (m) => {
  const curvyAggregator = m.contract("CurvyAggregator", ["0x70997970c51812dc3a010c7d01b50e0d17dc79c8"]);

  return { curvyAggregator };
});
