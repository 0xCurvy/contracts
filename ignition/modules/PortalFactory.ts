import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { encodeDeployData } from "viem";
import artifact from "../../artifacts/contracts/portal/PortalFactory.sol/PortalFactory.json";
import { getEnvironmentParameter } from "./utils/parameters";

export default buildModule("PortalFactory", (m) => {
  const ownerAddress = getEnvironmentParameter<`0x{string}`>("owner");

  const CREATEX_ADDRESS = "0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed";
  const createX = m.contractAt("ICreateX", CREATEX_ADDRESS, { id: "CreateX" });

  const initCode = encodeDeployData({
    abi: artifact.abi,
    bytecode: artifact.bytecode as `0x${string}`,
    args: [ownerAddress as `0x${string}`],
  });

  const create2Salt = getEnvironmentParameter<`0x{string}`>("create2_salt");
  if (!create2Salt) {
    throw new Error("Missing create2_salt environment variable");
  }

  const deployCall = m.call(createX, "deployCreate2(bytes32,bytes)", [create2Salt, initCode], {
    id: "CreateX_PortalFactory_V4",
  });

  const deployedAddress = m.readEventArgument(deployCall, "ContractCreation(address,bytes32)", "newContract", {
    id: "ReadEvent_PortalFactory_V4",
    emitter: createX,
  });

  const portalFactory = m.contractAt("PortalFactory", deployedAddress, {
    id: "PortalFactory_V4",
    after: [deployCall],
  });

  return { portalFactory };
});
