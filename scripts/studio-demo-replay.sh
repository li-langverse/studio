#!/usr/bin/env bash
# Headless native demo replay: DemoScript JSON → per-step PPM frames under build/demo-recorder/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"

SCRIPT_PATH="${1:-$STUDIO_ROOT/data/demo-scripts/workspace-tour.demo.json}"
SESSION="${2:-$(basename "$SCRIPT_PATH" .demo.json)}"
OUT_DIR="$STUDIO_ROOT/build/demo-recorder/$SESSION"
FRAMES_DIR="$OUT_DIR/frames"
TRACE_PATH="$OUT_DIR/demo_trace.jsonl"
SCRATCH="$STUDIO_ROOT/build/demo-recorder/scratch.ppm"
FPS="${STUDIO_DEMO_RECORDER_FPS:-30}"
MIN_SEC="${WORLD_STUDIO_DEMO_RECORDER_MIN_DURATION_SEC:-10}"
MIN_FRAMES="${STUDIO_DEMO_RECORDER_FRAME_COUNT:-$((FPS * MIN_SEC))}"

mkdir -p "$FRAMES_DIR" "$STUDIO_ROOT/build/demo-recorder" "$LIC_ROOT/build/demo-recorder"

LIC_BIN="$(resolve_lic || true)"
if [[ -z "$LIC_BIN" ]]; then
  LIC_BIN="$(command -v lic 2>/dev/null || true)"
fi
[[ -x "$LIC_BIN" ]] || { echo "studio-demo-replay: lic not found" >&2; exit 1; }

SCENARIO_ID="$(python3 "$STUDIO_ROOT/scripts/studio-demo-parse-json.py" "$SCRIPT_PATH")"
export STUDIO_DEMO_SCENARIO_ID="$SCENARIO_ID"

RUN_BIN="$LIC_ROOT/build/demo-recorder/demo_run"
SMOKE="packages/li-studio/li-tests/smoke/studio_demo_run.li"

(cd "$LIC_ROOT" && "$LIC_BIN" check "$SMOKE")
if [[ ! -x "$RUN_BIN" ]]; then
  (cd "$LIC_ROOT" && "$LIC_BIN" build "$SMOKE" -o build/demo-recorder/demo_run --allow-open-vc)
fi

rm -f "$TRACE_PATH" "$SCRATCH"
( cd "$STUDIO_ROOT" && "$RUN_BIN" ) || { echo "studio-demo-replay: demo_run failed" >&2; exit 1; }

python3 - "$FRAMES_DIR" "$OUT_DIR/capture-provenance.json" "$SCRIPT_PATH" "$FPS" "$MIN_FRAMES" <<'PY'
import hashlib, json, sys
from pathlib import Path
frames = Path(sys.argv[1])
prov = Path(sys.argv[2])
script = Path(sys.argv[3])
fps = int(sys.argv[4])
min_frames = int(sys.argv[5])
sha = hashlib.sha256(script.read_text(encoding="utf-8").encode()).hexdigest()[:16]
count = len(list(frames.glob("frame-*.ppm")))
prov.write_text(json.dumps({
    "native_pixels": True,
    "real_replay": True,
    "script_path": str(script),
    "script_hash": sha,
    "frame_count": count,
    "fps": fps,
    "min_frames": min_frames,
}, indent=2) + "\n", encoding="utf-8")
if count < min_frames:
    print(f"studio-demo-replay: only {count} frames (< {min_frames})", file=sys.stderr)
    sys.exit(1)
print(count)
PY

FRAME_COUNT="$(find "$FRAMES_DIR" -name 'frame-*.ppm' 2>/dev/null | wc -l | tr -d ' ')"

echo "studio-demo-replay: ${FRAME_COUNT} frames in $FRAMES_DIR (scenario_id=$SCENARIO_ID script=$SCRIPT_PATH)"
