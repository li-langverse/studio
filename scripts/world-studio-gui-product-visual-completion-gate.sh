#!/usr/bin/env bash
# Exit 0 only when all wsv-w* todos done, gates pass, PNGs meet heuristics.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export STUDIO_ROOT="$ROOT"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"

PLAN="$STUDIO_ROOT/docs/superpowers/plans/2026-06-02-world-studio-gui-product-visual-loop.md"
PNG_DIR="$STUDIO_ROOT/docs/demo/media/native-verticals/png"
MANIFEST="$STUDIO_ROOT/data/world-studio-gui-product-visual-loop/latest-screenshots.json"
MIN_BYTES="${WORLD_STUDIO_PRODUCT_VISUAL_MIN_PNG_BYTES:-12000}"
MIN_UNIQUE_COLORS="${WORLD_STUDIO_PRODUCT_VISUAL_MIN_UNIQUE_COLORS:-48}"

if [[ ! -f "$PLAN" ]]; then
  echo "world-studio-gui-product-visual completion gate: missing plan $PLAN" >&2
  exit 1
fi

if ! python3 - "$PLAN" <<'PY'
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8")
pending = []
for m in re.finditer(
    r"- id: (wsv-w\\S+)\\n\\s+content: [^\\n]+\\n\\s+status: (\\w+)", text
):
    if m.group(2) != "done":
        pending.append(m.group(1))
if pending:
    print("world-studio-gui-product-visual completion gate: pending todos:", ", ".join(pending), file=sys.stderr)
    sys.exit(1)
PY
then
  exit 1
fi

bash "$STUDIO_ROOT/scripts/world-studio-gui-product-visual-gates.sh"

required=(
  "product-visual-game-1280x720.png"
  "product-visual-game.png"
  "product-visual-sim_drug_design.png"
)

python3 - "$PNG_DIR" "$MANIFEST" "$MIN_BYTES" "$MIN_UNIQUE_COLORS" "${required[@]}" <<'PY'
import struct, sys, zlib
from pathlib import Path

png_dir = Path(sys.argv[1])
manifest = Path(sys.argv[2])
min_bytes = int(sys.argv[3])
min_colors = int(sys.argv[4])
required_names = sys.argv[5:]

def png_unique_colors(path: Path) -> int:
    data = path.read_bytes()
    if data[:8] != b"\\x89PNG\\r\\n\\x1a\\n":
        return 0
    pos = 8
    w = h = 0
    bit_depth = color_type = 0
    idat: list[bytes] = []
    while pos < len(data):
        if pos + 8 > len(data):
            break
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        ctype = data[pos + 4 : pos + 8]
        chunk = data[pos + 8 : pos + 8 + length]
        pos += 12 + length
        if ctype == b"IHDR" and length >= 13:
            w, h = struct.unpack(">II", chunk[:8])
            bit_depth = chunk[8]
            color_type = chunk[9]
        elif ctype == b"IDAT":
            idat.append(chunk)
    if not idat or w <= 0 or h <= 0 or bit_depth != 8 or color_type != 2:
        return 0
    if w * h > 4_000_000:
        return min_colors + 1
    try:
        raw = zlib.decompress(b"".join(idat))
    except zlib.error:
        return 0
    colors: set[tuple[int, int, int]] = set()
    row_bytes = 1 + w * 3
    off = 0
    for _y in range(h):
        if off + row_bytes > len(raw):
            break
        off += 1
        for _x in range(w):
            if off + 2 < len(raw):
                colors.add((raw[off], raw[off + 1], raw[off + 2]))
            off += 3
        if len(colors) >= min_colors:
            return len(colors)
    return len(colors)

missing = []
weak = []
for name in required_names:
    p = png_dir / name
    if not p.is_file():
        alt = png_dir / name.replace("-1280x720", "")
        if alt.is_file():
            p = alt
        else:
            missing.append(name)
            continue
    size = p.stat().st_size
    if size < min_bytes:
        weak.append(f"{name} ({size} bytes < {min_bytes})")
        continue
    uniq = png_unique_colors(p)
    if uniq < min_colors:
        weak.append(f"{name} (unique_colors~{uniq} < {min_colors}, likely wireframe)")

if missing:
    print("world-studio-gui-product-visual completion gate: missing PNGs:", ", ".join(missing), file=sys.stderr)
    sys.exit(1)
if weak:
    print("world-studio-gui-product-visual completion gate: PNG heuristics failed:", "; ".join(weak), file=sys.stderr)
    sys.exit(1)

if not manifest.is_file():
    print(f"world-studio-gui-product-visual completion gate: missing manifest {manifest}", file=sys.stderr)
    sys.exit(1)

print("world-studio-gui-product-visual completion gate: all wsv-w* done + PNGs pass heuristics")
PY

echo "world-studio-gui-product-visual completion gate: PASS"

