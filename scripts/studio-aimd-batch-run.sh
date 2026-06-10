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
# shellcheck source=_studio-aimd-env.sh
source "$ROOT/scripts/_studio-aimd-env.sh"
mkdir -p "$OUT_DIR"

LIC_BIN=""
LIC_BIN="$(resolve_lic 2>/dev/null || true)"
[[ -n "$LIC_BIN" && -x "$LIC_BIN" ]] || { echo "studio-aimd-batch-run: lic not found" >&2; exit 1; }

studio_aimd_export_batch_env "$SCENARIO"
STEPS="$STUDIO_AIMD_BATCH_STEPS"
DFT_STRIDE="$STUDIO_AIMD_DFT_STRIDE"
EXPECTED_DFT_CALLS="$(studio_aimd_expected_dft_calls "$STEPS" "$DFT_STRIDE")"

(cd "$LIC_ROOT" && "$LIC_BIN" check packages/li-sim-scientific/li-tests/smoke/echem_aimd_batch_smoke.li) \
  || { echo "studio-aimd-batch-run: echem_aimd_batch_smoke failed" >&2; exit 2; }

if [[ ! -x "$RUNNER" ]]; then
  (cd "$LIC_ROOT" && "$LIC_BIN" build --allow-open-vc --no-lean-verify "$RUNNER_SRC" -o "$RUNNER")
  chmod +x "$RUNNER" 2>/dev/null || true
fi

export STUDIO_AIMD_BATCH_OUT="$BATCH_JSON"
(cd "$STUDIO_ROOT" && "$RUNNER") || { echo "studio-aimd-batch-run: runner failed" >&2; exit 3; }

if [[ ! -f "$BATCH_JSON" ]]; then
  echo "studio-aimd-batch-run: missing $BATCH_JSON" >&2
  exit 4
fi

export STUDIO_AIMD_EXPECTED_DFT_CALLS="$EXPECTED_DFT_CALLS"
python3 - "$BATCH_JSON" "$STEPS" <<'PY'
import json, os, sys
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
if tier not in ("mvp_stub", "mvp_gpu_stub", "pilot"):
    raise SystemExit(f"batch tier must be mvp_stub, mvp_gpu_stub, or pilot, got {tier!r}")
if int(data.get("gpu_path", 0)) == 1 and tier not in ("mvp_gpu_stub", "pilot"):
    raise SystemExit("gpu_path=1 requires tier mvp_gpu_stub or pilot")
dft_stride = int(data.get("dft_stride", 0))
if tier == "pilot" and dft_stride < 1:
    raise SystemExit("pilot tier requires dft_stride >= 1")
dft_calls = int(data.get("dft_calls", 0))
if tier == "pilot" and dft_calls < 1:
    raise SystemExit("pilot tier requires dft_calls >= 1")
expected_stride = int(os.environ.get("STUDIO_AIMD_DFT_STRIDE", "50"))
expected_calls = int(os.environ.get("STUDIO_AIMD_EXPECTED_DFT_CALLS", "0"))
if int(data.get("dft_stride", 0)) != expected_stride:
    raise SystemExit(f"dft_stride {data.get('dft_stride')} != expected {expected_stride}")
if expected_calls > 0 and dft_calls != expected_calls:
    raise SystemExit(f"dft_calls {dft_calls} != expected {expected_calls}")
print("studio-aimd-batch-run: OK", path, f"dft_stride={expected_stride}", f"dft_calls={dft_calls}")
PY

FINAL_PPM="$OUT_DIR/final-frame.ppm"
AIMD_VIZ_SMOKE="packages/li-studio/li-tests/smoke/studio_aimd_final_viz.li"
if [[ -f "$STUDIO_ROOT/li-tests/smoke/studio_aimd_final_viz.li" ]]; then
  cp -f "$STUDIO_ROOT/li-tests/smoke/studio_aimd_final_viz.li" \
    "$LIC_ROOT/$AIMD_VIZ_SMOKE" 2>/dev/null || true
  cp -f "$STUDIO_ROOT/src/lib.li" "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null || true
  (cd "$LIC_ROOT" && "$LIC_BIN" check "$AIMD_VIZ_SMOKE") \
    || { echo "studio-aimd-batch-run: studio_aimd_final_viz smoke failed" >&2; exit 5; }
fi

CAPTURE_RUNNER="$STUDIO_ROOT/build/aimd-final-viz-capture"
CAPTURE_SRC="$STUDIO_ROOT/li-tests/smoke/studio_aimd_final_viz_capture.li"
if [[ -f "$CAPTURE_SRC" ]]; then
  if [[ ! -x "$CAPTURE_RUNNER" ]]; then
    (cd "$LIC_ROOT" && "$LIC_BIN" build --allow-open-vc --no-lean-verify "$CAPTURE_SRC" -o "$CAPTURE_RUNNER")
    chmod +x "$CAPTURE_RUNNER" 2>/dev/null || true
  fi
  mkdir -p "$OUT_DIR"
  export STUDIO_AIMD_FINAL_PPM="$FINAL_PPM"
  (cd "$STUDIO_ROOT" && "$CAPTURE_RUNNER") || { echo "studio-aimd-batch-run: final-frame capture failed" >&2; exit 6; }
  if [[ ! -f "$FINAL_PPM" ]]; then
    echo "studio-aimd-batch-run: missing $FINAL_PPM" >&2
    exit 7
  fi
fi
