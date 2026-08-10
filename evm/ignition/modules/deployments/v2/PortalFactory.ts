import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { encodeDeployData } from "viem";
import { fullyQualifiedName, readArtifact } from "../../../../artifact-registry.mjs";
import { getAddressParameter, getEnvironmentParameter } from "../../utils/parameters";

const artifact = readArtifact("PortalFactory");

/**
 * Greenfield V2 PortalFactory — a FRESH, independent CreateX deployment for the
 * standalone V2 stack. Same V2 `PortalFactory.sol` (EIP-1167 clone factory) as
 * the existing `deployments/PortalFactory.ts` (`PortalFactoryV2`), but salted
 * with the per-environment `create2_salt_v2` so it lands at a NEW deterministic
 * address and does not touch the live V1-era factory.
 *
 * Used only by the greenfield composition (`deployments/v2/Core.ts`) on the
 * fresh `<env>_<network>_v2` deployment ids.
 */
export default buildModule("PortalFactoryV2", (m) => {
  const ownerAddress = getEnvironmentParameter<`0x${string}`>("owner");

  const createXAddress = getAddressParameter("createXAddress", "network");
  const createX = m.contractAt(fullyQualifiedName("ICreateX"), createXAddress, { id: "CreateX" });

  if (!artifact.abi || !artifact.bytecode) {
    throw new Error("PortalFactory artifact is malformed: missing abi or bytecode");
  }

  const initCode = encodeDeployData({
    abi: artifact.abi,
    bytecode: artifact.bytecode as `0x${string}`,
    args: [ownerAddress as `0x${string}`],
  });

  const create2Salt = getEnvironmentParameter<`0x${string}`>("create2_salt_v2");
  if (!create2Salt) {
    throw new Error("Missing create2_salt_v2 environment parameter");
  }

  const deployCall = m.call(createX, "deployCreate2(bytes32,bytes)", [create2Salt, initCode], {
    id: "CreateX_Deploy",
  });

  const deployedAddress = m.readEventArgument(deployCall, "ContractCreation(address,bytes32)", "newContract", {
    id: "ReadEvent_NewContract",
    emitter: createX,
  });

  const portalFactory = m.contractAt(fullyQualifiedName("PortalFactory"), deployedAddress, {
    id: "PortalFactory",
    after: [deployCall],
  });

  return { portalFactory };
});
