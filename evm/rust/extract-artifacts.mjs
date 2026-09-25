#!/usr/bin/env node
// extract-artifacts.mjs — vendor the Hardhat artifacts the Rust bindings expand from,
// and stamp the provenance manifest that records what produced them.
//
// This is the Rust-side twin of `../scripts/extract-abis.ts`, which does the same for
// the TypeScript SDK.
//
//   node extract-artifacts.mjs --source-commit=<sha>   write artifacts + manifest
//   node extract-artifacts.mjs --check                 verify both are up to date
import { createHash } from "node:crypto";
import { mkdir, readdir, readFile, unlink, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { artifactPath, CONTRACTS as CONTRACTS_REGISTRY } from "../artifact-registry.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const artifactsDir = join(__dirname, "../artifacts");
const crateDir = join(__dirname, "curvy-bindings");
const outDir = join(crateDir, "src/artifacts");
const manifestPath = join(crateDir, "artifact-manifest.json");

/**
 * The bound contract set — everything `CurvyContractInstances::deploy_for_testing`
 * deploys, plus `Portal`, which is the typed surface for calling a user's deployed
 * portal (`shield` / `recover` / `bridge`). Ids resolve through the shared registry, so
 * moving a contract is a one-place edit.
 */
const BOUND = [
  "CurvyVaultV2",
  "CurvyAggregatorAlphaV2",
  "PortalFactory",
  "Portal",
  "CurvyAggregationVerifier",
  "CurvyPendingNotesCommitmentVerifier",
  "CurvyWithdrawalVerifier",
  "PoseidonT4",
  "ERC1967Proxy",
  "ERC20Mock",
  "Multicall3",
];

const CONTRACTS = BOUND.map((name) => ({
  name,
  artifact: artifactPath(name),
  devenv: CONTRACTS_REGISTRY[name].devenv ?? false,
}));

/** The contract whose compilation defines the manifest's toolchain record. */
const TOOLCHAIN_REFERENCE = "CurvyAggregatorAlphaV2";

const check = process.argv.includes("--check");
const sourceCommit = process.argv.find((a) => a.startsWith("--source-commit="))?.split("=")[1];
if (!check && !sourceCommit) {
  throw new Error("--source-commit=<sha> is required when writing (or pass --check)");
}

const sha256 = (s) => createHash("sha256").update(s).digest("hex");

function missingArtifact({ name, artifact, devenv }) {
  const remedy = devenv
    ? "HARDHAT_DEVENV=true pnpm --filter contracts build\n" + "  (devenv/** is only in paths.sources under that flag)"
    : "pnpm --filter contracts build";
  return new Error(`missing Hardhat artifact for ${name}: ${artifact}\n  run: ${remedy}`);
}

/**
 * Compiler settings come from the build-info of the compilation that actually produced
 * the bytecode, not from `hardhat.config.ts` — the config declares three solc profiles
 * (0.8.28 twice, 0.8.23 for CreateX) and describes intent, whereas build-info records
 * what happened. A profile reorder can therefore never make the manifest lie.
 */
async function readToolchain(buildInfoId) {
  const raw = await readFile(join(artifactsDir, "build-info", `${buildInfoId}.json`), "utf-8");
  const { solcVersion, input } = JSON.parse(raw);
  const { evmVersion, optimizer } = input?.settings ?? {};
  return {
    command: "packages/contracts/evm/rust/generate.sh",
    toolchain: "hardhat",
    solc_version: solcVersion,
    evm_version: evmVersion,
    optimizer_runs: optimizer?.runs ?? null,
  };
}

async function main() {
  await mkdir(outDir, { recursive: true });
  const digests = {};
  const stale = [];
  let toolchain;

  for (const contract of CONTRACTS) {
    const { name, artifact } = contract;
    let raw;
    try {
      raw = await readFile(join(artifactsDir, artifact), "utf-8");
    } catch {
      throw missingArtifact(contract);
    }
    const { abi, bytecode, deployedBytecode, buildInfoId } = JSON.parse(raw);
    if (!abi) throw new Error(`artifact ${artifact} is malformed: missing abi`);
    if (name === TOOLCHAIN_REFERENCE) toolchain = await readToolchain(buildInfoId);

    // `sol!` reads exactly these keys (alloy_json_abi::ContractObject). Keeping only
    // them makes the vendored copy stable against unrelated Hardhat metadata churn.
    // `deployedBytecode` is retained deliberately: it is what lets a deployment be
    // checked against the bindings with `eth_getCode`.
    const contents = `${JSON.stringify({ abi, bytecode, deployedBytecode }, null, 2)}\n`;
    const relative = `src/artifacts/${name}.json`;
    digests[relative] = sha256(contents);

    if (check) {
      const current = await readFile(join(outDir, `${name}.json`), "utf-8").catch(() => null);
      if (current !== contents) stale.push(relative);
    } else {
      await writeFile(join(outDir, `${name}.json`), contents);
    }
  }

  // Files nobody binds would still be shipped by `include = ["src/**"]`, so they are an
  // error rather than a warning: drop them when writing, report them when checking.
  const expected = new Set(CONTRACTS.map((c) => `${c.name}.json`));
  for (const file of await readdir(outDir)) {
    if (expected.has(file)) continue;
    if (check) stale.push(`src/artifacts/${file} (orphan — no longer bound)`);
    else {
      await unlink(join(outDir, file));
      console.log(`    removed orphan ${file}`);
    }
  }

  if (check) {
    const manifest = JSON.parse(await readFile(manifestPath, "utf-8").catch(() => "{}"));
    // `source_commit` deliberately not compared — it moves with every commit, and
    // generate.sh checks it for reachability instead.
    for (const [file, digest] of Object.entries(digests)) {
      if (manifest.sha256?.[file] !== digest) stale.push(`${file} (manifest hash)`);
    }
    if (stale.length) {
      for (const s of stale) console.error(`    STALE ${s}`);
      console.error("run generate.sh to refresh");
      process.exit(1);
    }
    console.log(`    ${CONTRACTS.length} artifacts and their manifest hashes are up to date`);
    return;
  }

  const cratePackage = await readFile(join(crateDir, "Cargo.toml"), "utf-8");
  const contracts = JSON.parse(await readFile(join(__dirname, "../package.json"), "utf-8"));
  const manifest = {
    schema_version: 2,
    crate_version: cratePackage.match(/^version = "(.+)"$/m)?.[1],
    contract_release: contracts.version,
    source_repository: "https://github.com/0xCurvy/curvy-monorepo",
    source_commit: sourceCommit,
    generator: toolchain,
    sha256: digests,
  };
  await writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  console.log(
    `    ${CONTRACTS.length} artifacts, solc ${toolchain.solc_version}/${toolchain.evm_version}, stamped at ${sourceCommit.slice(0, 9)}`,
  );
}

await main();
