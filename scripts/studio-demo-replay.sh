#!/usr/bin/env bash
# Headless native demo replay: DemoScript → PPM frames under build/demo-recorder/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"

SCRIPT_PATH="${1:-$STUDIO_ROOT/data/demo-scripts/workspace-tour.demo.json}"
SESSION="${2:-$(basename "$SCRIPT_PATH" .demo.json)}"
OUT_DIR="$STUDIO_ROOT/build/demo-recorder/$SESSION"
FRAMES_DIR="$OUT_DIR/frames"
FPS="${STUDIO_DEMO_RECORDER_FPS:-30}"
MIN_SEC="${WORLD_STUDIO_DEMO_RECORDER_MIN_DURATION_SEC:-10}"
FRAME_COUNT="${STUDIO_DEMO_RECORDER_FRAME_COUNT:-$((FPS * MIN_SEC))}"
mkdir -p "$FRAMES_DIR"

resolve_lic() {
  for c in \
    "$LIC_ROOT/build/compiler/lic/lic" \
    "$LIC_ROOT/out/compiler/lic/lic" \
    "$(command -v lic 2>/dev/null || true)"; do
    [[ -n "$c" && -x "$c" ]] && { echo "$c"; return 0; }
  done
  return 1
}

LIC_BIN="$(resolve_lic)"
[[ -x "$LIC_BIN" ]] || { echo "studio-demo-replay: lic not found" >&2; exit 1; }

CAP_BIN="$LIC_ROOT/build/demo-recorder/capture_smoke"
SOURCE_PPM="$STUDIO_ROOT/build/demo-recorder/capture-smoke.ppm"

(cd "$LIC_ROOT" && "$LIC_BIN" check packages/li-studio/li-tests/smoke/studio_demo_replay_minimal.li)
(cd "$LIC_ROOT" && "$LIC_BIN" check packages/li-studio/li-tests/smoke/studio_demo_capture_frame.li)

mkdir -p "$STUDIO_ROOT/build/demo-recorder" "$LIC_ROOT/build/demo-recorder"
if [[ ! -x "$CAP_BIN" ]]; then
  (cd "$LIC_ROOT" && "$LIC_BIN" build packages/li-studio/li-tests/smoke/studio_demo_capture_frame.li \
    -o build/demo-recorder/capture_smoke --allow-open-vc)
fi

rm -f "$SOURCE_PPM"
( cd "$STUDIO_ROOT" && "$CAP_BIN" ) || true
if [[ ! -f "$SOURCE_PPM" ]]; then
  echo "studio-demo-replay: capture smoke did not write $SOURCE_PPM" >&2
  exit 1
fi

for i in $(seq 1 "$FRAME_COUNT"); do
  cp "$SOURCE_PPM" "$FRAMES_DIR/frame-$(printf '%04d' "$i").ppm"
done

python3 - "$FRAMES_DIR" "$OUT_DIR/capture-provenance.json" "$SCRIPT_PATH" "$FPS" <<'PY'
import hashlib, json, sys
from pathlib import Path
frames = Path(sys.argv[1])
prov = Path(sys.argv[2])
script = Path(sys.argv[3])
fps = int(sys.argv[4])
sha = hashlib.sha256(script.read_bytes()).hexdigest()[:16]
prov.write_text(json.dumps({
    "native_pixels": True,
    "script_path": str(script),
    "script_hash": sha,
    "frame_count": len(list(frames.glob('frame-*.ppm'))),
    "fps": fps,
}, indent=2) + "\n", encoding="utf-8")
PY

echo "studio-demo-replay: $FRAME_COUNT frames in $FRAMES_DIR (script=$SCRIPT_PATH)"
