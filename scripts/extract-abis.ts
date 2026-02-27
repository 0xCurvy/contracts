#!/usr/bin/env node
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { glob } from "glob";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const artifactsDir = join(__dirname, "../ignition/deployments/local_anvil/artifacts");
const abiDir = join(process.cwd(), "../sdk/src/contracts/evm/abi");

function toCamelCase(str: string): string {
  return str.replace(/-([a-z])/g, (g) => g[1].toUpperCase());
}

async function main() {
  await mkdir(abiDir, { recursive: true });
  const files = await glob("**/*.json", {
    cwd: artifactsDir,
  });

  const contractToAbiName: Record<string, string> = {
    CurvyAggregatorAlpha: "aggregator-alpha",
    CurvyVault: "vault",
    PortalFactory: "portal-factory",
    Multicall3: "multicall3",
  };

  const contractImplementations: Record<string, string> = {
    CurvyAggregatorAlpha: "CurvyAggregatorAlphaV5Implementation",
    CurvyVault: "CurvyVaultV5Implementation",
    PortalFactory: "PortalFactory",
    Multicall3: "Multicall3",
  };

  for (const contract in contractImplementations) {
    const impl = contractImplementations[contract];
    const tsFileName = contractToAbiName[contract];

    if (tsFileName) {
      const artifactFile = files.find((f) => f.includes(`${contract}#${impl}`));
      if (artifactFile) {
        const content = await readFile(join(artifactsDir, artifactFile), "utf-8");
        const json = JSON.parse(content);
        const abi = json.abi;
        if (abi) {
          const variableName = toCamelCase(tsFileName) + "Abi";
          const tsContent = `export const ${variableName} = ${JSON.stringify(abi, null, 2)} as const;\n`;
          await writeFile(join(abiDir, `${tsFileName}.ts`), tsContent);
        }
      }
    }
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
