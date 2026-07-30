import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { encodeDeployData } from "viem";
import artifact from "../../../artifacts/src/v2/portal/PortalFactory.sol/PortalFactory.json";
import { getAddressParameter, getEnvironmentParameter } from "../utils/parameters";

/**
 * V2 PortalFactory building block — deployed deterministically via ICreateX
 * `deployCreate2` from the per-environment `create2_salt` + `owner`. The V2
 * `PortalFactory.sol` constructs `Portal` and `SolanaPortal` impls in its ctor
 * and uses them as EIP-1167 minimal-proxy clone templates.
 *
 * This is the factory used by the local devenv stack (and any greenfield
 * deploy). Its deployed-address key `PortalFactory#PortalFactory` is consumed
 * by `packages/devenv` (mock-server, add-localnet, tests) and the contracts
 * package tests — DO NOT rename the module or the final `contractAt` id.
 *
 * NOTE: the module id `"PortalFactory"` is intentionally shared with the frozen
 * `legacy/PortalFactory.ts` (the audited *V1* factory). They never appear in the
 * same deployment journal — this V2 block runs under `local_anvil`/greenfield
 * ids, while the legacy V1 block only reconciles the production/staging journals.
 * The production V2 factory is a separate module (`deployments/PortalFactory.ts`,
 * id `PortalFactoryV2`).
 */
export default buildModule("PortalFactory", (m) => {
  const ownerAddress = getEnvironmentParameter<`0x${string}`>("owner");

  const createXAddress = getAddressParameter("createXAddress", "network");
  const createX = m.contractAt("src/v2/utils/ICreateX.sol:ICreateX", createXAddress, { id: "CreateX" });

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

  const portalFactory = m.contractAt("src/v2/portal/PortalFactory.sol:PortalFactory", deployedAddress, {
    id: "PortalFactory",
    after: [deployCall],
  });

  return { portalFactory };
});
