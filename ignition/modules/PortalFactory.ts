import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { encodeDeployData } from "viem";
import artifact from "../../artifacts/contracts/portal/PortalFactory.sol/PortalFactory.json";
// audit(2026-Q1): Moving constant to JSON
import { getAddressParameter, getEnvironmentParameter } from "./utils/parameters";

export default buildModule("PortalFactory", (m) => {
  const ownerAddress = getEnvironmentParameter<`0x${string}`>("owner");

  // audit(2026-Q1): Moving constant to JSON - CreateX address now sourced per-network from network-parameters.json
  const createXAddress = getAddressParameter("createXAddress", "network");
  const createX = m.contractAt("ICreateX", createXAddress, { id: "CreateX" });

  // audit(2026-Q1): Moving constant to JSON - error message if artifact is malformed
  if (!artifact.abi || !artifact.bytecode) {
    throw new Error("PortalFactory artifact is malformed: missing abi or bytecode");
  }

  const initCode = encodeDeployData({
    abi: artifact.abi,
    bytecode: artifact.bytecode as `0x${string}`,
    args: [ownerAddress as `0x${string}`],
  });

  const create2Salt = getEnvironmentParameter<`0x${string}`>("create2_salt");
  if (!create2Salt) {
    throw new Error("Missing create2_salt environment variable");
  }

  const deployCall = m.call(createX, "deployCreate2(bytes32,bytes)", [create2Salt, initCode], {
    id: "CreateX_PortalFactory",
  });

  const deployedAddress = m.readEventArgument(deployCall, "ContractCreation(address,bytes32)", "newContract", {
    id: "ReadEvent_PortalFactory",
    emitter: createX,
  });

  const portalFactory = m.contractAt("PortalFactory", deployedAddress, {
    after: [deployCall],
  });

  return { portalFactory };
});
