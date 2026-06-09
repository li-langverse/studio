#!/usr/bin/env bash
# W2 — headless AIMD batch + final-frame capture (native Li; no UI step replay).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export STUDIO_ROOT="$ROOT"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"

SCENARIO="${1:-$STUDIO_ROOT/data/world-studio-aimd-demo-loop/hero-scenario.json}"
OUT_DIR="${2:-$STUDIO_ROOT/build/aimd-demo/out}"
RUNNER="$LIC_ROOT/build/aimd-demo/aimd_hero_runner"
SMOKE="packages/li-studio/li-tests/smoke/studio_aimd_hero_runner.li"

[[ -f "$SCENARIO" ]] || { echo "studio-aimd-batch-run: missing scenario $SCENARIO" >&2; exit 1; }
mkdir -p "$OUT_DIR" "$LIC_ROOT/build/aimd-demo" "$STUDIO_ROOT/build/aimd-demo/out"

LIC_BIN="$(resolve_lic || true)"
[[ -x "$LIC_BIN" ]] || LIC_BIN="$(command -v lic 2>/dev/null || true)"
[[ -x "$LIC_BIN" ]] || { echo "studio-aimd-batch-run: lic not found" >&2; exit 1; }

cp -f "$STUDIO_ROOT/src/lib.li" "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null || true
cp -f "$STUDIO_ROOT/li-tests/smoke/studio_aimd_hero_runner.li" "$LIC_ROOT/$SMOKE" 2>/dev/null || true

export STUDIO_AIMD_BATCH_STEPS
STUDIO_AIMD_BATCH_STEPS="$(python3 - "$SCENARIO" <<'PY'
import json, sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(int(data.get("steps", 5000)))
PY
)"

(cd "$LIC_ROOT" && "$LIC_BIN" check "$SMOKE" --workspace=packages/li.toml) || exit 2
if [[ ! -x "$RUNNER" ]]; then
  (cd "$LIC_ROOT" && "$LIC_BIN" build "$SMOKE" -o build/aimd-demo/aimd_hero_runner --allow-open-vc) || exit 3
fi

( cd "$STUDIO_ROOT" && "$RUNNER" ) || { echo "studio-aimd-batch-run: runner failed" >&2; exit 4; }

FINAL="$OUT_DIR/final-frame.ppm"
[[ -f "$FINAL" ]] || { echo "studio-aimd-batch-run: missing $FINAL" >&2; exit 5; }
[[ -f "$OUT_DIR/batch-result.json" ]] || { echo "studio-aimd-batch-run: missing batch-result.json" >&2; exit 6; }

echo "studio-aimd-batch-run: OK steps=$STUDIO_AIMD_BATCH_STEPS"
