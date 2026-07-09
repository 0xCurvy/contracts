#!/usr/bin/env bash
# generate.sh — regenerate `curvy-bindings`' committed sol! codegen from the contract
# SOURCES, mirroring how hoprnet/contracts generates `hopr-bindings` (forge bind
# --alloy, committed expanded output, one snake_case file per contract).
#
# Deterministic: pinned forge version + pinned solc/optimizer settings (foundry.toml
# at the package root mirrors hardhat.config.ts's profile). Running this twice on the
# same sources yields byte-identical codegen.
#
#   ./generate.sh          regenerate src/codegen/** + the unlinked aggregator bytecode
#   ./generate.sh --check  regenerate to a temp dir and diff against the committed files
#
# PARITY GATE (always runs): the forge-built creation bytecode of every bound contract
# is compared against the Hardhat artifact the validated deploy pipeline uses
# (../artifacts/**). The executable bytecode must be byte-identical; ONLY the CBOR
# metadata blobs (solc `ipfs` hash of compiler input, which legitimately differs
# between the Hardhat and Foundry builds of the same source) may differ. Library link
# placeholders (`__$…$__`, a keccak of the build-relative fully-qualified library name,
# so also build-system-dependent) are normalised before comparing. Any divergence
# beyond that FAILS the script — bindings must never deploy different bytecode than
# what the pipeline validated.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # packages/contracts/evm/bindings
EVM_ROOT="$(dirname "$HERE")"                          # packages/contracts/evm
CRATE="$HERE/curvy-bindings"

# ── pinned toolchain ──────────────────────────────────────────────────────────────────
# forge 1.5.1 emits the alloy-2.x codegen shape hopr-bindings 4.9.x uses
# (`FooInstance<P, N>`, `__provider`, snake_case module files). Install side-by-side
# with `foundryup -i 1.5.1` (does NOT have to be the active default).
FORGE_VERSION="1.5.1"
FORGE="${FORGE:-$HOME/.foundry/versions/v$FORGE_VERSION/forge}"
if [ ! -x "$FORGE" ]; then
  echo "FATAL: pinned forge $FORGE_VERSION not found at $FORGE" >&2
  echo "       install it with: foundryup -i $FORGE_VERSION" >&2
  exit 1
fi
"$FORGE" --version | head -1

# ── the bound contract set (== everything CurvyContractInstances::deploy_for_testing
#    deploys, plus Portal for event/call typing) ──────────────────────────────────────
SOURCES=(
  src/v2/vault/CurvyVaultV2.sol
  src/v2/aggregator-alpha/CurvyAggregatorAlphaV2.sol
  src/v2/portal/PortalFactory.sol
  src/v2/portal/Portal.sol
  src/v2/aggregator-alpha/verifiers/CurvyAggregationVerifier.sol
  src/v2/aggregator-alpha/verifiers/CurvyPendingNotesCommitmentVerifier.sol
  src/v2/aggregator-alpha/verifiers/CurvyWithdrawalVerifier.sol
  src/v2/utils/PoseidonT4.sol
  devenv/ERC20Mock.sol
  devenv/Multicall3.sol
  node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol
)
SELECT='^(CurvyVaultV2|CurvyAggregatorAlphaV2|PortalFactory|Portal|CurvyAggregationVerifier|CurvyPendingNotesCommitmentVerifier|CurvyWithdrawalVerifier|PoseidonT4|ERC1967Proxy|ERC20Mock|Multicall3)$'

cd "$EVM_ROOT"

echo "==> forge build (solc 0.8.28 / cancun / optimizer 200 — see foundry.toml)"
"$FORGE" build "${SOURCES[@]}" >/dev/null
OUT="$EVM_ROOT/bindings/curvy-bindings/.forge/out"

# ── PARITY GATE ───────────────────────────────────────────────────────────────────────
echo "==> parity gate: forge creation bytecode vs Hardhat artifacts (../artifacts)"
python3 - "$OUT" "$EVM_ROOT/artifacts" <<'PY'
import json, re, sys
out, hh = sys.argv[1], sys.argv[2]
# contract -> (forge out subdir, hardhat artifact path under artifacts/)
M = {
  "CurvyVaultV2": ("CurvyVaultV2.sol", "src/v2/vault/CurvyVaultV2.sol/CurvyVaultV2.json"),
  "CurvyAggregatorAlphaV2": ("CurvyAggregatorAlphaV2.sol", "src/v2/aggregator-alpha/CurvyAggregatorAlphaV2.sol/CurvyAggregatorAlphaV2.json"),
  "PortalFactory": ("PortalFactory.sol", "src/v2/portal/PortalFactory.sol/PortalFactory.json"),
  "Portal": ("Portal.sol", "src/v2/portal/Portal.sol/Portal.json"),
  "CurvyAggregationVerifier": ("CurvyAggregationVerifier.sol", "src/v2/aggregator-alpha/verifiers/CurvyAggregationVerifier.sol/CurvyAggregationVerifier.json"),
  "CurvyPendingNotesCommitmentVerifier": ("CurvyPendingNotesCommitmentVerifier.sol", "src/v2/aggregator-alpha/verifiers/CurvyPendingNotesCommitmentVerifier.sol/CurvyPendingNotesCommitmentVerifier.json"),
  "CurvyWithdrawalVerifier": ("CurvyWithdrawalVerifier.sol", "src/v2/aggregator-alpha/verifiers/CurvyWithdrawalVerifier.sol/CurvyWithdrawalVerifier.json"),
  "PoseidonT4": ("PoseidonT4.sol", "src/v2/utils/PoseidonT4.sol/PoseidonT4.json"),
  "ERC1967Proxy": ("ERC1967Proxy.sol", "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol/ERC1967Proxy.json"),
  "ERC20Mock": ("ERC20Mock.sol", "devenv/ERC20Mock.sol/ERC20Mock.json"),
  "Multicall3": ("Multicall3.sol", "devenv/Multicall3.sol/Multicall3.json"),
}
PLACE = re.compile(r"__\$[0-9a-fA-F]{34}\$__")            # solc library link placeholder
CBOR  = re.compile(r"a264697066735822[0-9a-f]{68}64736f6c6343[0-9a-f]{6}0033")  # ipfs metadata blob
def norm(h): return PLACE.sub("00" * 20, h)
ok = True
for name, (sol, hhrel) in M.items():
    f = json.load(open(f"{out}/{sol}/{name}.json"))["bytecode"]["object"].removeprefix("0x")
    h = json.load(open(f"{hh}/{hhrel}"))["bytecode"].removeprefix("0x")
    f, h = norm(f), norm(h)
    if f == h:
        verdict = "EXACT"
    else:
        fs, hs = CBOR.sub("", f), CBOR.sub("", h)
        nf, nh = len(CBOR.findall(f)), len(CBOR.findall(h))
        if fs == hs and nf == nh:
            verdict = f"MODULO-METADATA ({nf} blob{'s' if nf > 1 else ''})"
        else:
            verdict = "DIVERGENT"
            ok = False
    print(f"    {name:<38} {verdict}")
if not ok:
    print("PARITY GATE FAILED: executable bytecode diverges beyond metadata", file=sys.stderr)
    sys.exit(1)
print("    parity gate PASSED")
PY

# ── forge bind ────────────────────────────────────────────────────────────────────────
MODE="${1:-}"
if [ "$MODE" = "--check" ]; then
  DEST="$(mktemp -d)/codegen"
else
  DEST="$CRATE/src/codegen"
fi

echo "==> forge bind --alloy → $DEST"
"$FORGE" bind --alloy --module --overwrite --skip-build --skip-cargo-toml \
  --select "$SELECT" \
  --bindings-path "$DEST" >/dev/null

# The aggregator links the PoseidonT4 library, so forge emits its module WITHOUT a
# BYTECODE static. Extract the unlinked creation bytecode (placeholder intact) for
# constants.rs (include_str!) — config.rs links it at deploy time.
UNLINKED_DEST="$CRATE/curvy_aggregator_alpha_v2_unlinked.hex"
[ "$MODE" = "--check" ] && UNLINKED_DEST="$(dirname "$DEST")/curvy_aggregator_alpha_v2_unlinked.hex"
python3 - "$OUT/CurvyAggregatorAlphaV2.sol/CurvyAggregatorAlphaV2.json" "$UNLINKED_DEST" <<'PY'
import json, sys
bc = json.load(open(sys.argv[1]))["bytecode"]["object"].removeprefix("0x")
assert bc.count("__$") == 1, "expected exactly one PoseidonT4 link placeholder"
open(sys.argv[2], "w").write(bc + "\n")
PY
echo "    wrote $(basename "$UNLINKED_DEST") ($(wc -c < "$UNLINKED_DEST") bytes)"

if [ "$MODE" = "--check" ]; then
  echo "==> --check: diffing regenerated output against committed files"
  diff -r "$DEST" "$CRATE/src/codegen"
  diff "$UNLINKED_DEST" "$CRATE/curvy_aggregator_alpha_v2_unlinked.hex"
  echo "    committed codegen is up to date"
else
  echo "==> done — codegen refreshed in $DEST"
fi
