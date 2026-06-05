#!/usr/bin/env bash
# PNG/PPM frame dir → H.264 MP4 (yuv420p 30fps) + provenance sidecar.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"

FRAMES_DIR="${1:-$STUDIO_ROOT/build/demo-recorder/workspace-tour/frames}"
OUT_MP4="${2:-$STUDIO_ROOT/build/demo-recorder/out/workspace-tour.mp4}"
FPS="${3:-30}"

command -v ffmpeg >/dev/null 2>&1 || { echo "studio-demo-encode-mp4: ffmpeg required" >&2; exit 1; }
mkdir -p "$(dirname "$OUT_MP4")"

LIST="$FRAMES_DIR/concat.txt"
: > "$LIST"
shopt -s nullglob
for f in "$FRAMES_DIR"/frame-*.ppm; do
  abs="$(cd "$(dirname "$f")" && pwd)/$(basename "$f")"
  echo "file '$abs'" >> "$LIST"
  echo "duration $(awk "BEGIN{print 1/$FPS}")" >> "$LIST"
done
shopt -u nullglob

if [[ ! -s "$LIST" ]]; then
  echo "studio-demo-encode-mp4: no frames in $FRAMES_DIR" >&2
  exit 1
fi

ffmpeg -y -f concat -safe 0 -i "$LIST" -vf "format=yuv420p" -r "$FPS" -c:v libx264 -pix_fmt yuv420p "$OUT_MP4"

PROV="$(dirname "$OUT_MP4")/capture-provenance.json"
python3 - "$OUT_MP4" "$PROV" <<'PY'
import json, subprocess, sys
from pathlib import Path
mp4 = Path(sys.argv[1])
prov = Path(sys.argv[2])
dur = 0.0
try:
    r = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", str(mp4)],
        capture_output=True, text=True, check=True,
    )
    dur = float(r.stdout.strip())
except Exception:
    pass
data = {"mp4": str(mp4), "duration_s": dur, "native_pixels": True}
if prov.is_file():
    data.update(json.loads(prov.read_text(encoding="utf-8")))
prov.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
print(f"studio-demo-encode-mp4: {mp4} ({dur:.1f}s)")
PY
