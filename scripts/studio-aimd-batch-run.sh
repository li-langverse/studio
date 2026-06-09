#!/usr/bin/env bash
# W2 — headless AIMD batch runner: configure from scenario JSON → batch compute → artifacts.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export STUDIO_ROOT="$ROOT"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"

SCENARIO="${1:-$STUDIO_ROOT/data/world-studio-aimd-demo-loop/hero-scenario.json}"
OUT_DIR="${2:-$STUDIO_ROOT/build/aimd-demo/out}"

[[ -f "$SCENARIO" ]] || { echo "studio-aimd-batch-run: missing scenario $SCENARIO" >&2; exit 1; }
mkdir -p "$OUT_DIR"

LIC_BIN=""
LIC_BIN="$(resolve_lic)" || { echo "studio-aimd-batch-run: lic not found" >&2; exit 1; }

STEPS="$(python3 - "$SCENARIO" <<'PY'
import json, sys
print(int(json.load(open(sys.argv[1], encoding="utf-8")).get("steps", 5000)))
PY
)"
export STUDIO_AIMD_BATCH_STEPS="$STEPS"
export WORLD_STUDIO_AIMD_DEMO_MIN_STEPS="$STEPS"

RUNNER_BIN="$STUDIO_ROOT/build/aimd-demo/studio-aimd-hero-runner"
SMOKE_REL="packages/li-studio/li-tests/smoke/studio_aimd_hero_runner.li"
mkdir -p "$(dirname "$RUNNER_BIN")"
(
  cd "$LIC_ROOT"
  "$LIC_BIN" check "$SMOKE_REL" --no-cache >/dev/null
  "$LIC_BIN" build "$SMOKE_REL" -o "$RUNNER_BIN" --allow-open-vc >/dev/null
)

(cd "$STUDIO_ROOT" && "$RUNNER_BIN")
[[ -f "$OUT_DIR/batch-result.json" ]] || { echo "studio-aimd-batch-run: missing batch-result.json" >&2; exit 2; }
[[ -f "$OUT_DIR/final-frame.ppm" ]] || { echo "studio-aimd-batch-run: missing final-frame.ppm" >&2; exit 3; }

echo "studio-aimd-batch-run: OK steps=$STEPS out=$OUT_DIR"
