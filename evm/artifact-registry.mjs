/**
 * Single source of truth for "which compiled artifact is which contract".
 *
 * Hardhat expresses the same fact two ways — an artifact path
 * (`src/v2/portal/PortalFactory.sol/PortalFactory.json`) and a fully qualified name
 * (`src/v2/portal/PortalFactory.sol:PortalFactory`) — and both were previously spelled
 * out as literals in four independent places: the SDK ABI extractor, the Rust bindings
 * extractor, and the Ignition modules (as JSON imports and as `m.contractAt` names).
 * Moving a contract meant a four-place edit with nothing tying them together.
 *
 * Keys are LOGICAL ids, not contract names, because the v1/v2 split left several
 * contracts sharing a short name (three different `PortalFactory.sol`). `contract`
 * defaults to the key and is only set where they differ.
 *
 * Plain ESM so a bare `node` script, a `hardhat run` TypeScript script, and the Ignition
 * modules can all import it without a build step.
 */

import { readFileSync } from "node:fs";

/** @typedef {{ source: string, contract?: string, devenv?: boolean }} ContractEntry */
/** @typedef {keyof typeof CONTRACTS} ContractId */

/**
 * The Solidity contract name for an id — the explicit `contract` when the id differs
 * from it (the v1/v2 duplicates), otherwise the id itself.
 * @template {ContractId} K
 * @typedef {(typeof CONTRACTS)[K] extends { contract: infer C extends string } ? C : K} ContractName
 */

/**
 * Fully qualified names as a LITERAL type, not `string`.
 *
 * This matters: Hardhat's generated `ArtifactMap` is keyed by literal FQNs, and it is
 * the only way to type an ambiguous short name (three `PortalFactory.sol` across v1/v2
 * make `getContractAt("PortalFactory", …)` resolve to `never`). A helper returning
 * plain `string` would miss the map and degrade every call back to `unknown`.
 * @template {ContractId} K
 * @typedef {`${(typeof CONTRACTS)[K]["source"]}:${ContractName<K>}`} FullyQualifiedName
 */

/**
 * `@satisfies` rather than `@type`: it still checks every entry against `ContractEntry`,
 * but keeps the literal key union so `ContractId` is the exact set of ids. With `@type`
 * the keys widen to `string` and a typo'd id only fails at runtime.
 *
 * The inner `@type {const}` is load-bearing too: without it the `source` values widen to
 * `string`, and `FullyQualifiedName` degrades to `` `${string}:Foo` `` — which no longer
 * matches Hardhat's literal-keyed `ArtifactMap`.
 * @satisfies {Record<string, ContractEntry>}
 */
export const CONTRACTS = /** @type {const} */ ({
  // ── v2 (current) ────────────────────────────────────────────────────────────────
  CurvyAggregatorAlphaV2: { source: "src/v2/aggregator-alpha/CurvyAggregatorAlphaV2.sol" },
  CurvyVaultV2: { source: "src/v2/vault/CurvyVaultV2.sol" },
  PortalFactory: { source: "src/v2/portal/PortalFactory.sol" },
  Portal: { source: "src/v2/portal/Portal.sol" },
  CurvyAggregationVerifier: { source: "src/v2/aggregator-alpha/verifiers/CurvyAggregationVerifier.sol" },
  CurvyPendingNotesCommitmentVerifier: {
    source: "src/v2/aggregator-alpha/verifiers/CurvyPendingNotesCommitmentVerifier.sol",
  },
  CurvyWithdrawalVerifier: { source: "src/v2/aggregator-alpha/verifiers/CurvyWithdrawalVerifier.sol" },
  PoseidonT4: { source: "src/v2/utils/PoseidonT4.sol" },
  ICreateX: { source: "src/v2/utils/ICreateX.sol" },

  // ── third party ─────────────────────────────────────────────────────────────────
  ERC1967Proxy: { source: "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol" },

  // ── devenv fixtures ─────────────────────────────────────────────────────────────
  // Only compiled when HARDHAT_DEVENV=true puts `devenv` in `paths.sources`.
  ERC20Mock: { source: "devenv/ERC20Mock.sol", devenv: true },
  Multicall3: { source: "devenv/Multicall3.sol", devenv: true },

  // ── v1 / legacy (still referenced by the legacy Ignition modules) ───────────────
  PortalFactoryV1: { source: "src/v1/portal/v1/PortalFactory.sol", contract: "PortalFactory" },
  PoseidonT4V1: { source: "src/v1/aggregator-alpha/utils/PoseidonT4.sol", contract: "PoseidonT4" },
  ICreateXV1: { source: "src/v1/utils/ICreateX.sol", contract: "ICreateX" },
});

/** @param {ContractId} id */
function entry(id) {
  const found = CONTRACTS[id];
  if (!found) throw new Error(`unknown contract id: ${id}`);
  return { ...found, contract: found.contract ?? id };
}

/**
 * Path of the Hardhat artifact, relative to `artifacts/`.
 * @param {ContractId} id
 */
export function artifactPath(id) {
  const { source, contract } = entry(id);
  return `${source}/${contract}.json`;
}

/**
 * Solidity fully qualified name, as Hardhat and Ignition spell it.
 *
 * Ignition records this string in its deployment journals, so it must stay stable for
 * an already-deployed module — changing what an id resolves to is a breaking change to
 * every journal that mentions it, not just a rename.
 * @template {ContractId} K
 * @param {K} id
 * @returns {FullyQualifiedName<K>}
 */
export function fullyQualifiedName(id) {
  const { source, contract } = entry(id);
  return /** @type {FullyQualifiedName<K>} */ (`${source}:${contract}`);
}

/**
 * Reads a compiled Hardhat artifact by id. Resolved relative to this file so it does
 * not depend on the caller's depth or on `process.cwd()`.
 * @param {ContractId} id
 */
export function readArtifact(id) {
  const url = new URL(`./artifacts/${artifactPath(id)}`, import.meta.url);
  return JSON.parse(readFileSync(url, "utf-8"));
}
