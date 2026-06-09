#!/usr/bin/env bash
# Visual acceptance for demo-recorder MP4s / frame dirs (W11).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"

FRAMES_DIR="${1:-$STUDIO_ROOT/build/demo-recorder/command-palette/frames}"
MIN_UNIQUE="${STUDIO_DEMO_MIN_UNIQUE_COLORS:-3}"
STRICT_VISUAL="${STUDIO_DEMO_STRICT_VISUAL:-0}"
MIN_FRAMES="${STUDIO_DEMO_MIN_FRAME_DELTA:-0}"

python3 - "$FRAMES_DIR" "$MIN_UNIQUE" "$MIN_FRAMES" "$STRICT_VISUAL" <<'PY'
import hashlib
import sys
from pathlib import Path

frames_dir = Path(sys.argv[1])
min_unique = int(sys.argv[2])
min_delta = int(sys.argv[3])
strict_visual = int(sys.argv[4]) if len(sys.argv) > 4 else 0
files = sorted(frames_dir.glob("frame-*.ppm"))
if len(files) < 2:
    print(f"studio-demo-visual-gate: need >=2 frames in {frames_dir}", file=sys.stderr)
    sys.exit(1)

def ppm_stats(path: Path) -> tuple[int, str]:
    data = path.read_bytes()
    if not data.startswith(b"P6"):
        raise ValueError(f"not P6: {path}")
    pos = 2
    while pos < len(data) and data[pos:pos+1] in b" \t\r\n":
        pos += 1
    while pos < len(data) and data[pos:pos+1] == b"#":
        while pos < len(data) and data[pos:pos+1] != b"\n":
            pos += 1
        pos += 1
        while pos < len(data) and data[pos:pos+1] in b" \t\r\n":
            pos += 1
    end = data.find(b"\n", pos)
    wh = data[pos:end].decode().strip().split()
    w, h = int(wh[0]), int(wh[1])
    pos = end + 1
    while pos < len(data) and data[pos:pos+1] in b" \t\r\n":
        pos += 1
    end = data.find(b"\n", pos)
    pos = end + 1
    rgb = data[pos:pos + w * h * 3]
    uniq = len(set(tuple(rgb[i:i+3]) for i in range(0, len(rgb), 3)))
    digest = hashlib.sha256(rgb).hexdigest()
    return uniq, digest

hashes = []
uniq_max = 0
for f in files:
    u, h = ppm_stats(f)
    hashes.append(h)
    uniq_max = max(uniq_max, u)

distinct = len(set(hashes))
pair_deltas = sum(1 for i in range(1, len(hashes)) if hashes[i] != hashes[i - 1])

errors = []
if uniq_max < min_unique:
    errors.append(f"unique_colors {uniq_max} < {min_unique} on {files[-1].name}")
if strict_visual == 1 and distinct < 2:
    errors.append(f"strict visual: only {distinct} distinct frame hash(es) across {len(files)} frames")
if min_delta > 0 and pair_deltas < min_delta:
    errors.append(f"frame hash delta insufficient: {pair_deltas} adjacent pairs differ across {len(files)} frames")

if errors:
    for e in errors:
        print(f"studio-demo-visual-gate: {e}", file=sys.stderr)
    sys.exit(1)

print(f"studio-demo-visual-gate: OK ({len(files)} frames, unique={uniq_max}, distinct_hashes={distinct}, pair_deltas={pair_deltas})")
PY
