#!/usr/bin/env bash
# W8 completion — tunable dft_stride (dev 50 / real 1) + honest trace + optional 5000-DFT smoke.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"
# shellcheck source=_studio-aimd-env.sh
source "$ROOT/scripts/_studio-aimd-env.sh"

GOAL="$ROOT/data/goal-directed-sprints/world-studio-aimd-dft-tunable-gpu.md"
ASSESSMENT="$ROOT/data/world-studio-aimd-demo-loop/latest-iteration-assessment.json"
TRACE="$ROOT/data/world-studio-aimd-demo-loop/latest-demo-trace.json"
SCENARIO="$ROOT/data/world-studio-aimd-demo-loop/hero-scenario.json"

[[ -f "$GOAL" ]] || { echo "W8 completion: missing goal $GOAL" >&2; exit 1; }

bash "$ROOT/scripts/world-studio-aimd-demo-gates.sh"

# Fast gate: dev stride 50 → 100 DFT calls @ 5000 steps (md_step 0..4999, every 50)
unset REAL_AIMD
export STUDIO_AIMD_DFT_STRIDE=50
bash "$ROOT/scripts/studio-aimd-hero-demo.sh"

python3 - "$TRACE" <<'PY'
import json, sys
from pathlib import Path
trace = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if int(trace.get("dft_stride", 0)) != 50:
    raise SystemExit(f"fast gate trace dft_stride={trace.get('dft_stride')} expected 50")
calls = int(trace.get("dft_calls", 0))
if calls != 100:
    raise SystemExit(f"fast gate trace dft_calls={calls} expected 100 @ stride 50 / 5000 steps")
print("W8 fast gate: dft_stride=50 dft_calls=100 OK")
PY

# W8c GPU north star — STUDIO_AIMD_GPU=1 + LKIR scaffold → gpu_path=1 in trace
if [[ -f "$LIC_ROOT/packages/li-chem/li-tests/smoke/chem_dft_gpu_path_probe.li" ]]; then
  (cd "$LIC_ROOT" && "$(resolve_lic 2>/dev/null || command -v lic)" check packages/li-chem/li-tests/smoke/chem_dft_gpu_path_probe.li) \
    || { echo "W8c completion: chem_dft_gpu_path_probe failed" >&2; exit 1; }
  export STUDIO_AIMD_GPU=1
  export STUDIO_AIMD_PILOT=1
  studio_aimd_export_batch_env "$SCENARIO"
  BATCH_JSON="$ROOT/build/aimd-demo/out/batch-result.json"
  RUNNER="$ROOT/build/aimd-batch-runner"
  RUNNER_SRC="$LIC_ROOT/packages/li-sim-scientific/li-tests/smoke/echem_aimd_batch_runner.li"
  LIC_BIN="$(resolve_lic 2>/dev/null || command -v lic)"
  mkdir -p "$ROOT/build/aimd-demo/out"
  if [[ ! -x "$RUNNER" ]]; then
    (cd "$LIC_ROOT" && "$LIC_BIN" build --allow-open-vc --no-lean-verify "$RUNNER_SRC" -o "$RUNNER")
  fi
  (cd "$ROOT" && "$RUNNER")
  python3 - "$ROOT/build/aimd-demo/out/batch-result.json" <<'PY'
import json, sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if int(data.get("gpu_path", 0)) != 1:
    raise SystemExit(f"W8c gpu gate gpu_path={data.get('gpu_path')} expected 1 with STUDIO_AIMD_GPU=1")
if data.get("tier") not in ("pilot", "mvp_gpu_stub"):
    raise SystemExit(f"W8c gpu gate tier={data.get('tier')!r} expected pilot or mvp_gpu_stub")
print("W8c gpu gate: gpu_path=1 OK")
PY
  unset STUDIO_AIMD_GPU
fi

# Optional slow path: REAL_AIMD=1 → stride 1, full 5000 DFT evals
if [[ "${REAL_AIMD_COMPLETION:-0}" == "1" ]]; then
  export REAL_AIMD=1
  studio_aimd_export_batch_env "$SCENARIO"
  echo "W8 slow gate: REAL_AIMD=1 stride=$STUDIO_AIMD_DFT_STRIDE steps=$STUDIO_AIMD_BATCH_STEPS"
  bash "$ROOT/scripts/studio-aimd-batch-run.sh" "$SCENARIO"
  python3 - "$ROOT/build/aimd-demo/out/batch-result.json" <<'PY'
import json, sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if int(data.get("dft_stride", 0)) != 1:
    raise SystemExit(f"slow gate dft_stride={data.get('dft_stride')} expected 1")
if int(data.get("dft_calls", 0)) != 5000:
    raise SystemExit(f"slow gate dft_calls={data.get('dft_calls')} expected 5000")
print("W8 slow gate: dft_stride=1 dft_calls=5000 OK")
PY
else
  echo "W8 slow gate: skipped (set REAL_AIMD_COMPLETION=1 for 5000-DFT proof)"
fi

python3 - "$GOAL" "$ASSESSMENT" "$TRACE" <<'PY'
import json, re, sys
from pathlib import Path

goal = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
assessment_path = Path(sys.argv[2])
assessment = {}
if assessment_path.is_file():
    assessment = json.loads(assessment_path.read_text(encoding="utf-8"))
errors = []
for m in re.finditer(r"\| (W8\w+) \|[^|]+\| pending \|", goal):
    wp = m.group(1)
    # W8c engine GPU north star — defer when honest blocker documented in assessment
    if wp == "W8c" and assessment.get("science_gpu_blocker"):
        continue
    errors.append(f"W8 goal still pending: {wp}")
if errors:
    for e in errors:
        print(f"world-studio-aimd-dft-tunable-gpu completion gate: {e}", file=sys.stderr)
    sys.exit(1)
print("world-studio-aimd-dft-tunable-gpu completion gate: OK")
PY
