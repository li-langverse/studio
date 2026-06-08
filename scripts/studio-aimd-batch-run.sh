#!/usr/bin/env bash
# W2 — headless AIMD batch runner: scenario JSON → echem_aimd_batch_run → batch-result.json
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export STUDIO_ROOT="$ROOT"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"

SCENARIO="${1:-$STUDIO_ROOT/data/world-studio-aimd-demo-loop/hero-scenario.json}"
OUT_DIR="${2:-$STUDIO_ROOT/build/aimd-demo/out}"
RUNNER="$STUDIO_ROOT/build/aimd-batch-runner"
BATCH_JSON="$OUT_DIR/batch-result.json"
RUNNER_SRC="$LIC_ROOT/packages/li-sim-scientific/li-tests/smoke/echem_aimd_batch_runner.li"

[[ -f "$SCENARIO" ]] || { echo "studio-aimd-batch-run: missing scenario $SCENARIO" >&2; exit 1; }
mkdir -p "$OUT_DIR"

LIC_BIN=""
LIC_BIN="$(resolve_lic 2>/dev/null || true)"
[[ -n "$LIC_BIN" && -x "$LIC_BIN" ]] || { echo "studio-aimd-batch-run: lic not found" >&2; exit 1; }

STEPS="$(python3 - "$SCENARIO" <<'PY'
import json, sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(int(data.get("steps", 5000)))
PY
)"

export STUDIO_AIMD_BATCH_STEPS="$STEPS"

(cd "$LIC_ROOT" && "$LIC_BIN" check packages/li-sim-scientific/li-tests/smoke/echem_aimd_batch_smoke.li) \
  || { echo "studio-aimd-batch-run: echem_aimd_batch_smoke failed" >&2; exit 2; }

if [[ ! -x "$RUNNER" ]]; then
  (cd "$LIC_ROOT" && "$LIC_BIN" build --allow-open-vc --no-lean-verify "$RUNNER_SRC" -o "$RUNNER")
fi

export STUDIO_AIMD_BATCH_OUT="$BATCH_JSON"
(cd "$STUDIO_ROOT" && "$RUNNER") || { echo "studio-aimd-batch-run: runner failed" >&2; exit 3; }

if [[ ! -f "$BATCH_JSON" ]]; then
  echo "studio-aimd-batch-run: missing $BATCH_JSON" >&2
  exit 4
fi

python3 - "$BATCH_JSON" "$STEPS" <<'PY'
import json, sys
from pathlib import Path
path = Path(sys.argv[1])
steps = int(sys.argv[2])
data = json.loads(path.read_text(encoding="utf-8"))
if int(data.get("steps", 0)) < steps:
    raise SystemExit(f"batch steps {data.get('steps')} < expected {steps}")
if int(data.get("ok", 0)) != 1:
    raise SystemExit("batch ok != 1")
if float(data.get("checksum", 0)) <= 0:
    raise SystemExit("batch checksum invalid")
tier = data.get("tier", "")
if tier not in ("mvp_stub", "mvp_gpu_stub"):
    raise SystemExit(f"batch tier must be mvp_stub or mvp_gpu_stub, got {tier!r}")
if int(data.get("gpu_path", 0)) == 1 and tier != "mvp_gpu_stub":
    raise SystemExit("gpu_path=1 requires tier mvp_gpu_stub")
print("studio-aimd-batch-run: OK", path)
PY
