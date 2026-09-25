#!/usr/bin/env bash
# generate.sh — refresh the inputs `curvy-bindings` binds, from the HARDHAT artifacts
# the validated Ignition deploy pipeline produces.
#
# The crate contains no generated Rust: `src/codegen/mod.rs` is a short hand-written set
# of `alloy::sol!` invocations that expand the vendored artifacts in
# `curvy-bindings/src/artifacts/` at compile time. So "generating bindings" means
# refreshing those artifacts and re-stamping the provenance manifest — both of which
# `extract-artifacts.mjs` owns. This script adds only what it cannot know: the source
# commit, and whether that commit is reachable.
#
#   ./generate.sh          refresh src/artifacts/** and re-stamp the manifest
#   ./generate.sh --check  verify both are up to date (CI gate)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # packages/contracts/evm/rust
EVM_ROOT="$(dirname "$HERE")"                          # packages/contracts/evm
MANIFEST="$HERE/curvy-bindings/artifact-manifest.json"
MODE="${1:-}"

if [ -n "$MODE" ] && [ "$MODE" != "--check" ]; then
  echo "usage: $(basename "$0") [--check]" >&2
  exit 2
fi

SOURCE_COMMIT="$(git -C "$EVM_ROOT" rev-parse HEAD)"

# `devenv/**` (ERC20Mock, Multicall3) is only in `paths.sources` when HARDHAT_DEVENV is
# set, and EVERY ordinary hardhat task recompiles without it — `hardhat compile`,
# `hardhat run`, even `ignition visualize` — silently emptying artifacts/devenv/. So the
# precondition breaks constantly in normal use. Restore it here instead of relying on
# whoever ran last to have remembered the flag.
if [ ! -f "$EVM_ROOT/artifacts/devenv/ERC20Mock.sol/ERC20Mock.json" ]; then
  echo "==> devenv artifacts absent — recompiling with HARDHAT_DEVENV=true"
  (cd "$EVM_ROOT" && HARDHAT_DEVENV=true pnpm hardhat compile >/dev/null)
fi

echo "==> hardhat artifacts + provenance manifest"
if [ "$MODE" = "--check" ]; then
  node "$HERE/extract-artifacts.mjs" --check
else
  node "$HERE/extract-artifacts.mjs" "--source-commit=$SOURCE_COMMIT"
fi

# The stamped commit must be reachable, otherwise "which source produced these bindings"
# dead-ends. In --check mode the manifest may name an older commit than HEAD, so read it
# back; when writing we just stamped HEAD.
echo "==> provenance"
if [ "$MODE" = "--check" ]; then
  STAMPED="$(node -e 'process.stdout.write(require(process.argv[1]).source_commit)' "$MANIFEST")"
else
  STAMPED="$SOURCE_COMMIT"
fi

if ! git -C "$EVM_ROOT" cat-file -e "${STAMPED}^{commit}" 2>/dev/null; then
  # A shallow clone simply does not have the object, which is not the same as the commit
  # being unreachable. Don't fail on it — but say so.
  echo "    WARNING: source_commit ${STAMPED:0:9} not present locally — cannot verify"
  echo "             reachability (shallow clone? use fetch-depth: 0 to check it)"
elif git -C "$EVM_ROOT" merge-base --is-ancestor "$STAMPED" HEAD 2>/dev/null; then
  echo "    source_commit ${STAMPED:0:9} is reachable from HEAD"
else
  echo "FATAL: artifact-manifest.json source_commit $STAMPED is not reachable from HEAD" >&2
  echo "       re-run generate.sh after the rebase or amend that orphaned it" >&2
  exit 1
fi

[ "$MODE" = "--check" ] && echo "==> all up to date" || echo "==> done"
