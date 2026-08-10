import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/**
 * Deploys the production ENS CCIP-Read offchain resolver (ERC-3668 + ENSIP-10),
 * consolidated from the former `packages/ens-resolver/contracts` Hardhat project.
 *
 * `OffchainResolver(string url, address[] signers)`:
 *   - `url`     the CCIP-Read gateway endpoint the resolver points lookups at
 *               (e.g. https://<gateway>/gateway/{sender}/{data}.json).
 *   - `signers` the ECDSA addresses whose signed gateway responses
 *               `resolveWithProof` will accept. MUST include the gateway
 *               service's `ERC3668_SIGNER_KEY` address, or resolution reverts.
 *
 * Pass values via `--parameters`:
 *   { "OffchainResolver": { "gatewayUrl": "https://…", "signers": ["0x…"] } }
 *
 * This is a plain (non-proxy) `Ownable` contract. ENS registration is a separate
 * governance step: once deployed, point the Curvy ENS name's resolver at the
 * deployed address with `scripts/register-resolver.ts`.
 */
export default buildModule("OffchainResolver", (m) => {
  const gatewayUrl = m.getParameter<string>("gatewayUrl");
  const signers = m.getParameter<string[]>("signers");

  const offchainResolver = m.contract("OffchainResolver", [gatewayUrl, signers]);

  return { offchainResolver };
});
