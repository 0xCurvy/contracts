#!/usr/bin/env node
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const artifactsDir = join(__dirname, "../artifacts/");
const abiDir = join(process.cwd(), "../sdk/src/contracts/evm/abi/");

/**
 * Deployed contracts whose ABIs ship in the SDK. Artifact paths are explicit
 * (relative to `artifacts/`) because after the v1/v2 split several contracts
 * share a short name (e.g. three `PortalFactory.sol`), so a name/glob match is
 * ambiguous — the path pins the exact compiled artifact the deploy uses.
 */
const exports: { artifact: string; tsFile: string; varName: string }[] = [
  {
    artifact: "src/v2/aggregator-alpha/CurvyAggregatorAlphaV2.sol/CurvyAggregatorAlphaV2.json",
    tsFile: "aggregator-alpha-v2",
    varName: "aggregatorAlphaV2Abi",
  },
  {
    artifact: "src/v2/vault/CurvyVaultV2.sol/CurvyVaultV2.json",
    tsFile: "vault",
    varName: "vaultAbi",
  },
  {
    artifact: "src/v2/portal/PortalFactory.sol/PortalFactory.json",
    tsFile: "portal-factory",
    varName: "portalFactoryAbi",
  },
];

async function main() {
  await mkdir(abiDir, { recursive: true });

  for (const { artifact, tsFile, varName } of exports) {
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
