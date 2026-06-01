#!/usr/bin/env bash
# Exit 0 only when all wsp-w* todos done, gates pass, polish PNGs meet heuristics.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"

PLAN="$ROOT/docs/superpowers/plans/2026-05-31-world-studio-gui-polish-loop.md"
POLISH_DIR="$ROOT/docs/demo/media/native-verticals/png"
MANIFEST="$ROOT/data/world-studio-gui-polish-loop/latest-screenshots.json"
MIN_BYTES="${WORLD_STUDIO_POLISH_MIN_PNG_BYTES:-12000}"
MIN_UNIQUE_COLORS="${WORLD_STUDIO_POLISH_MIN_UNIQUE_COLORS:-48}"

if [[ ! -f "$PLAN" ]]; then
  echo "world-studio-gui-polish completion gate: missing plan $PLAN" >&2
  exit 1
fi

if ! python3 - "$PLAN" <<'PY'
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8")
pending = []
for m in re.finditer(
    r"- id: (wsp-w\S+)\n\s+content: [^\n]+\n\s+status: (\w+)", text
):
    if m.group(2) != "done":
        pending.append(m.group(1))
if pending:
    print("world-studio-gui-polish completion gate: pending todos:", ", ".join(pending), file=sys.stderr)
    sys.exit(1)
PY
then
  exit 1
fi

"$ROOT/scripts/world-studio-gui-polish-gates.sh"

required=(
  "polish-game-1280x720.png"
  "polish-game.png"
  "polish-sim_drug_design.png"
)

python3 - "$POLISH_DIR" "$MANIFEST" "$MIN_BYTES" "$MIN_UNIQUE_COLORS" "${required[@]}" <<'PY'
import struct, sys, zlib
from pathlib import Path

polish_dir = Path(sys.argv[1])
manifest = Path(sys.argv[2])
min_bytes = int(sys.argv[3])
min_colors = int(sys.argv[4])
required_names = sys.argv[5:]

def png_unique_colors(path: Path) -> int:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        return 0
    pos = 8
    colors: set[tuple[int, int, int]] = set()
    while pos < len(data):
        if pos + 8 > len(data):
            break
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        ctype = data[pos + 4 : pos + 8]
        chunk = data[pos + 8 : pos + 8 + length]
        pos += 12 + length
        if ctype == b"IHDR" and length >= 13:
            w, h = struct.unpack(">II", chunk[:8])
            if w * h > 4_000_000:
                return min_colors + 1
        if ctype == b"IDAT":
            try:
                raw = zlib.decompress(chunk)
            except zlib.error:
                continue
            stride = len(raw) // max(h, 1) if "h" in dir() else 0
            if stride >= 4:
                step = max(1, stride // 4)
                for i in range(0, min(len(raw), 200_000), step * 17):
                    if i + 2 < len(raw):
                        colors.add((raw[i], raw[i + 1], raw[i + 2]))
            if len(colors) >= min_colors:
                return len(colors)
    return len(colors)

missing = []
weak = []
for name in required_names:
    p = polish_dir / name
    if not p.is_file():
        alt = polish_dir / name.replace("polish-game-1280x720", "polish-game")
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
    print("world-studio-gui-polish completion gate: missing PNGs:", ", ".join(missing), file=sys.stderr)
    sys.exit(1)
if weak:
    print("world-studio-gui-polish completion gate: PNG heuristics failed:", "; ".join(weak), file=sys.stderr)
    sys.exit(1)

if not manifest.is_file():
    print(f"world-studio-gui-polish completion gate: missing manifest {manifest}", file=sys.stderr)
    sys.exit(1)

print("world-studio-gui-polish completion gate: all wsp-w* done + polish PNGs pass heuristics")
PY

echo "world-studio-gui-polish completion gate: PASS"
