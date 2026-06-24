import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { encodeDeployData } from "viem";
import artifact from "../../../artifacts/src/v1/portal/PortalFactory.sol/PortalFactory.json";
import { getAddressParameter, getEnvironmentParameter } from "../utils/parameters";

/**
 * V2 PortalFactory deploy. Same ICreateX + CREATE2 flow as the audited V1
 * module, but the underlying `PortalFactory.sol` now deploys EIP-1167 minimal
 * proxies (a `Portal` and `SolanaPortal` impl are constructed inside the
 * factory ctor and become clone templates). Different bytecode → different
 * CREATE2 address than the V1 factory, even with the same salt.
 *
 * Module name and future IDs are distinct from V1's so this can be appended
 * to the same `--deployment-id` journal without reconciliation collisions.
 */
export default buildModule("PortalFactory", (m) => {
  const ownerAddress = getEnvironmentParameter<`0x${string}`>("owner");

  const createXAddress = getAddressParameter("createXAddress", "network");
  const createX = m.contractAt("src/v1/utils/ICreateX.sol:ICreateX", createXAddress, { id: "CreateX" });

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
    id: "CreateX_Deploy",
  });

  const deployedAddress = m.readEventArgument(deployCall, "ContractCreation(address,bytes32)", "newContract", {
    id: "ReadEvent_NewContract",
    emitter: createX,
  });

  const portalFactory = m.contractAt("src/v1/portal/PortalFactory.sol:PortalFactory", deployedAddress, {
    id: "PortalFactory",
    after: [deployCall],
  });

  return { portalFactory };
});
