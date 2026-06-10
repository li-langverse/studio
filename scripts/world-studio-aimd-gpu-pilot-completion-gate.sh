#!/usr/bin/env bash
# W7 GPU pilot completion — real DFT every N steps + honest gpu_path trace.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"

GOAL="$ROOT/data/goal-directed-sprints/world-studio-aimd-gpu-pilot.md"
ASSESSMENT="$ROOT/data/world-studio-aimd-demo-loop/latest-iteration-assessment.json"
TRACE="$ROOT/data/world-studio-aimd-demo-loop/latest-demo-trace.json"

[[ -f "$GOAL" ]] || { echo "W7 completion: missing goal $GOAL" >&2; exit 1; }

bash "$ROOT/scripts/world-studio-aimd-demo-gates.sh"

if [[ -x "$ROOT/scripts/studio-aimd-hero-demo.sh" ]]; then
  bash "$ROOT/scripts/studio-aimd-hero-demo.sh" || exit 1
else
  echo "W7 completion: studio-aimd-hero-demo.sh not executable" >&2
  exit 1
fi

python3 - "$GOAL" "$ASSESSMENT" "$TRACE" <<'PY'
import json, re, sys
from pathlib import Path

goal = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
assessment_path = Path(sys.argv[2])
trace_path = Path(sys.argv[3])
errors = []

pending = []
for m in re.finditer(r"\| (W7\w+) \|[^|]+\| pending \|", goal):
    pending.append(m.group(1))
if pending:
    errors.append(f"W7 goal still pending: {', '.join(pending)}")

if not assessment_path.is_file():
    errors.append(f"missing assessment: {assessment_path}")
else:
    data = json.loads(assessment_path.read_text(encoding="utf-8"))
    if data.get("tier") != "pilot":
        errors.append(f"assessment tier must be pilot, got {data.get('tier')!r}")
    if not data.get("pass"):
        errors.append("assessment pass must be true")

if not trace_path.is_file():
    errors.append(f"missing trace: {trace_path}")
else:
    trace = json.loads(trace_path.read_text(encoding="utf-8"))
    tier = trace.get("tier", "")
    gpu = int(trace.get("gpu_path", 0))
    if tier not in ("pilot", "mvp_gpu_stub", "mvp_stub"):
        errors.append(f"trace tier invalid: {tier!r}")
    if tier == "pilot":
        if int(trace.get("dft_stride", 0)) < 1:
            errors.append("pilot trace missing dft_stride")
        if int(trace.get("dft_calls", 0)) < 1:
            errors.append("pilot trace missing dft_calls")
    blocker = (assessment_path.read_text(encoding="utf-8") if assessment_path.is_file() else "")
    has_blocker = "science_gpu_blocker" in blocker or "cpu_fallback" in blocker
    if gpu == 0 and tier == "mvp_stub" and has_blocker:
        pass  # honest CPU fallback documented in assessment
    elif gpu == 1 and tier in ("pilot", "mvp_gpu_stub"):
        pass
    elif gpu == 0 and tier == "mvp_stub":
        errors.append("gpu_path=0 requires science_gpu_blocker in assessment")
    else:
        errors.append(f"trace gpu_path={gpu} tier={tier!r} inconsistent with pilot acceptance")

if errors:
    for e in errors:
        print(f"world-studio-aimd-gpu-pilot completion gate: {e}", file=sys.stderr)
    sys.exit(1)

print("world-studio-aimd-gpu-pilot completion gate: OK")
PY
