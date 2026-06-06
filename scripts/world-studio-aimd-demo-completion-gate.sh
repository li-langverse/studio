#!/usr/bin/env bash
# Exit 0 when all aimd-w* todos done and hero demo artifacts exist.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"

PLAN="$ROOT/docs/superpowers/plans/2026-06-06-world-studio-aimd-demo-loop.md"
OUT_DIR="$ROOT/build/aimd-demo/out"
MANIFEST="$ROOT/data/world-studio-aimd-demo-loop/latest-demo-trace.json"
FINAL_FRAME="$OUT_DIR/final-frame.ppm"
MIN_STEPS="${WORLD_STUDIO_AIMD_DEMO_MIN_STEPS:-5000}"

if ! python3 - "$PLAN" <<'PY'
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
pending = []
matched = 0
for m in re.finditer(r"- id: (aimd-w\S+)\n\s+content: [^\n]+\n\s+status: (\w+)", text):
    matched += 1
    if m.group(2) != "done":
        pending.append(m.group(1))
if matched == 0:
    print("completion gate: no aimd-w* todos matched", file=sys.stderr)
    sys.exit(1)
if pending:
    print("completion gate: pending:", ", ".join(pending), file=sys.stderr)
    sys.exit(1)
PY
then
  exit 1
fi

bash "$ROOT/scripts/world-studio-aimd-demo-gates.sh"

if [[ -x "$ROOT/scripts/studio-aimd-hero-demo.sh" ]]; then
  bash "$ROOT/scripts/studio-aimd-hero-demo.sh" || exit 1
else
  echo "completion gate: studio-aimd-hero-demo.sh not yet executable (W5)" >&2
  exit 1
fi

python3 - "$FINAL_FRAME" "$MANIFEST" "$MIN_STEPS" <<'PY'
import json, sys
from pathlib import Path

final = Path(sys.argv[1])
manifest = Path(sys.argv[2])
min_steps = int(sys.argv[3])
errors = []

if not final.is_file():
    errors.append(f"missing final frame: {final}")
elif final.stat().st_size < 4096:
    errors.append(f"final frame too small: {final}")

if manifest.is_file():
    data = json.loads(manifest.read_text(encoding="utf-8"))
    steps = int(data.get("steps", 0))
    if steps < min_steps:
        errors.append(f"trace steps {steps} < {min_steps}")
    if not data.get("native_only", True):
        errors.append("native_only must be true")
else:
    errors.append(f"missing manifest: {manifest}")

if errors:
    for e in errors:
        print(f"world-studio-aimd-demo completion gate: {e}", file=sys.stderr)
    sys.exit(1)

print("world-studio-aimd-demo completion gate: OK")
PY
