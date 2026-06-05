#!/usr/bin/env bash
# Exit 0 when all wrec-w* todos done and acceptance MP4s meet heuristics.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"

PLAN="$ROOT/docs/superpowers/plans/2026-06-03-world-studio-gui-demo-recorder-loop.md"
OUT_DIR="$ROOT/build/demo-recorder/out"
MANIFEST="$ROOT/data/world-studio-gui-demo-recorder-loop/latest-videos.json"
MIN_DURATION="${WORLD_STUDIO_DEMO_RECORDER_MIN_DURATION_SEC:-10}"

if ! python3 - "$PLAN" <<'PY'
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8")
pending = []
matched = 0
for m in re.finditer(r"- id: (wrec-w\S+)\n\s+content: [^\n]+\n\s+status: (\w+)", text):
    matched += 1
    if m.group(2) != "done":
        pending.append(m.group(1))
if matched == 0:
    print("completion gate: no wrec-w* todos matched", file=sys.stderr)
    sys.exit(1)
if pending:
    print("completion gate: pending:", ", ".join(pending), file=sys.stderr)
    sys.exit(1)
PY
then
  exit 1
fi

bash "$ROOT/scripts/world-studio-gui-demo-recorder-gates.sh"

if [[ -x "$ROOT/scripts/studio-demo-visual-gate.sh" ]]; then
  for scenario in workspace-tour command-palette agent-invoke; do
    frames="$OUT_DIR/../$scenario/frames"
    if [[ -d "$frames" ]]; then
      bash "$ROOT/scripts/studio-demo-visual-gate.sh" "$frames" || exit 1
    fi
  done
fi

required=(
  "workspace-tour.mp4"
  "command-palette.mp4"
  "agent-invoke.mp4"
)

python3 - "$OUT_DIR" "$MANIFEST" "$MIN_DURATION" "${required[@]}" <<'PY'
import json, subprocess, sys
from pathlib import Path

out_dir = Path(sys.argv[1])
manifest = Path(sys.argv[2])
min_dur = float(sys.argv[3])
required = sys.argv[4:]
errors = []

def duration(path: Path) -> float:
    try:
        r = subprocess.run(
            ["ffprobe", "-v", "error", "-show_entries", "format=duration",
             "-of", "default=noprint_wrappers=1:nokey=1", str(path)],
            capture_output=True, text=True, check=True,
        )
        return float(r.stdout.strip())
    except Exception:
        return 0.0

videos = []
for name in required:
    p = out_dir / name
    if not p.is_file():
        errors.append(f"missing {p}")
        continue
    d = duration(p)
    if d < min_dur:
        errors.append(f"{name}: duration {d:.1f}s < {min_dur}s")
    videos.append({"file": str(p.relative_to(out_dir.parent.parent) if out_dir.is_relative_to(out_dir.parent.parent) else p), "duration_s": d})

if errors:
    for e in errors:
        print(f"world-studio-gui-demo-recorder completion gate: {e}", file=sys.stderr)
    sys.exit(1)

manifest.parent.mkdir(parents=True, exist_ok=True)
manifest.write_text(json.dumps({"native_only": True, "videos": videos, "paths": [v["file"] for v in videos]}, indent=2) + "\n", encoding="utf-8")
print("world-studio-gui-demo-recorder completion gate: OK")
PY

bash "$ROOT/scripts/world-studio-gui-demo-recorder-phase2-merge-gate.sh"
