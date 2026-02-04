import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { encodeDeployData, getContractAddress } from "viem";
import artifact from "../../artifacts/contracts/portal/PortalFactory.sol/PortalFactory.json";
import { getEnvironmentParameter, getNetworkParameter } from "./utils/deployment";

export default buildModule("PortalFactoryModule", (m) => {
  const ownerAddress = getNetworkParameter("owner");

  const CREATEX_ADDRESS = "0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed";
  const createX = m.contractAt("ICreateX", CREATEX_ADDRESS, { id: "CreateX" });

  const salt = "0x7374616765206d696861696c6f2c76616e6a6120637572767920706f77657200";

  const initCode = encodeDeployData({
    abi: artifact.abi,
    bytecode: artifact.bytecode as `0x${string}`,
    args: [ownerAddress as `0x${string}`],
  });

  const predictedAddress = getContractAddress({
    from: CREATEX_ADDRESS as `0x${string}`,
    salt: salt as `0x${string}`,
    bytecode: initCode,
    opcode: "CREATE2",
  });

  const create2Salt = getEnvironmentParameter<`0x{string}`>("create2_salt");
  if (!create2Salt) {
    throw new Error("Missing create2_salt environment variable");
  }
  const deployCall = m.call(createX, "deployCreate2(bytes32,bytes)", [create2Salt, initCode], {
    id: "CreateX_PortalFactory_Deploy",
  });

  const portalFactory = m.contractAt("PortalFactory", predictedAddress, {
    after: [deployCall],
  });

  return { portalFactory };
});
