#!/usr/bin/env bash
# Hero demo orchestrator (W5): configure → batch run → final frame capture.
# Stub until W1–W4 land; exits non-zero with clear message.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export STUDIO_ROOT="$ROOT"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"

SCENARIO="$STUDIO_ROOT/data/world-studio-aimd-demo-loop/hero-scenario.json"
OUT_DIR="$STUDIO_ROOT/build/aimd-demo/out"
TRACE="$STUDIO_ROOT/data/world-studio-aimd-demo-loop/latest-demo-trace.json"

[[ -f "$SCENARIO" ]] || { echo "studio-aimd-hero-demo: missing $SCENARIO" >&2; exit 1; }
mkdir -p "$OUT_DIR"

if [[ ! -x "$STUDIO_ROOT/scripts/studio-aimd-batch-run.sh" ]]; then
  echo "studio-aimd-hero-demo: W2 not landed — studio-aimd-batch-run.sh missing" >&2
  exit 2
fi

bash "$STUDIO_ROOT/scripts/studio-aimd-batch-run.sh" "$SCENARIO" "$OUT_DIR" || exit 3

python3 - "$SCENARIO" "$OUT_DIR" "$TRACE" <<'PY'
import json, sys
from pathlib import Path

scenario = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
out_dir = Path(sys.argv[2])
trace_path = Path(sys.argv[3])
final = out_dir / "final-frame.ppm"
batch_meta = out_dir / "batch-result.json"
steps = scenario.get("steps", 5000)
meta = {}
if batch_meta.is_file():
    meta = json.loads(batch_meta.read_text(encoding="utf-8"))
trace = {
    "native_only": True,
    "scenario": scenario.get("name"),
    "steps": meta.get("steps", steps),
    "checksum": meta.get("checksum"),
    "gpu_path": meta.get("gpu_path", 0),
    "tier": meta.get("tier", "stub"),
    "final_frame": str(final.relative_to(out_dir.parent.parent)) if final.is_file() else None,
}
trace_path.parent.mkdir(parents=True, exist_ok=True)
trace_path.write_text(json.dumps(trace, indent=2) + "\n", encoding="utf-8")
print("studio-aimd-hero-demo: trace written", trace_path)
if not final.is_file():
    print("studio-aimd-hero-demo: missing final frame", final, file=sys.stderr)
    sys.exit(4)
PY

echo "studio-aimd-hero-demo: OK"
