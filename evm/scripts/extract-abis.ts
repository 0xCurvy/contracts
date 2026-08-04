#!/usr/bin/env node
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { artifactPath, type ContractId } from "../artifact-registry.mjs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const artifactsDir = join(__dirname, "../artifacts/");
// SDK ABI directory. Resolve from __dirname (not process.cwd()) so it's invariant
// to where the script is invoked from. After the packages reorg the SDK moved to
// `packages/@0xcurvy/sdk`; this path is `<repo>/packages/@0xcurvy/sdk/...`
// (scripts → evm → contracts → packages → @0xcurvy/sdk).
const abiDir = join(__dirname, "../../../@0xcurvy/sdk/src/contracts/evm/abi/");

/**
 * Deployed contracts whose ABIs ship in the SDK. `contract` is a logical id resolved
 * through the shared registry — the v1/v2 split left several contracts sharing a short
 * name (three `PortalFactory.sol`), so the registry is what pins the exact compiled
 * artifact the deploy uses.
 */
const exports: { contract: ContractId; tsFile: string; varName: string }[] = [
  {
    contract: "CurvyAggregatorAlphaV2",
    tsFile: "aggregator-alpha-v2",
    varName: "aggregatorAlphaV2Abi",
  },
  // The v3 stack (SDK actions, portal-broadcaster, devenv deploy) imports the vault
  // ABI as `vaultV2Abi` from `vault-v2.ts`; the legacy backend still imports `vaultAbi`
  // from `vault.ts`. Both are the CurvyVaultV2 ABI — emit both from the one artifact so
  // they stay in lockstep (drop the `vault`/`vaultAbi` entry once the legacy backend is gone).
  { contract: "CurvyVaultV2", tsFile: "vault-v2", varName: "vaultV2Abi" },
  { contract: "CurvyVaultV2", tsFile: "vault", varName: "vaultAbi" },
  { contract: "PortalFactory", tsFile: "portal-factory", varName: "portalFactoryAbi" },
];

async function main() {
  await mkdir(abiDir, { recursive: true });

  for (const { contract, tsFile, varName } of exports) {
    const artifact = artifactPath(contract);
    const content = await readFile(join(artifactsDir, artifact), "utf-8");
    const { abi } = JSON.parse(content);
    if (!abi) {
      throw new Error(`Artifact ${artifact} is malformed: missing abi`);
    }

    const tsContent = `export const ${varName} = ${JSON.stringify(abi, null, 2)} as const;\n`;
    await writeFile(join(abiDir, `${tsFile}.ts`), tsContent);
    console.log(`Wrote ${tsFile}.ts (${varName}) from ${artifact}`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
