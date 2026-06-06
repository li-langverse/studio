#!/usr/bin/env bash
# Exit 0 only when all wtfx-w* todos done, gates pass, typography-fx PNGs meet heuristics.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"

PLAN="$ROOT/docs/superpowers/plans/2026-06-03-world-studio-typography-fx-animation-loop.md"
PNG_DIR="$ROOT/docs/demo/media/native-verticals/png"
MANIFEST="$ROOT/data/world-studio-typography-fx-animation-loop/latest-screenshots.json"
MIN_BYTES="${WORLD_STUDIO_TYPOGRAPHY_FX_MIN_PNG_BYTES:-12000}"
MIN_UNIQUE_COLORS="${WORLD_STUDIO_TYPOGRAPHY_FX_MIN_UNIQUE_COLORS:-48}"

if [[ ! -f "$PLAN" ]]; then
  echo "world-studio-typography-fx-animation completion gate: missing plan $PLAN" >&2
  exit 1
fi

if ! python3 - "$PLAN" <<'PY'
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8")
pending = []
matched = 0
for m in re.finditer(
    r"- id: (wtfx-w\S+)\n\s+content: [^\n]+\n\s+status: (\w+)", text
):
    matched += 1
    if m.group(2) != "done":
        pending.append(m.group(1))
if matched == 0:
    print(
        "world-studio-typography-fx-animation completion gate: no wtfx-w* todos matched in plan YAML",
        file=sys.stderr,
    )
    sys.exit(1)
if pending:
    print(
        "world-studio-typography-fx-animation completion gate: pending todos:",
        ", ".join(pending),
        file=sys.stderr,
    )
    sys.exit(1)
PY
then
  exit 1
fi

bash "$ROOT/scripts/world-studio-typography-fx-animation-gates.sh"

required=(
  "typography-fx-game-1280x720.png"
  "typography-fx-game.png"
  "typography-fx-inspector-panel.png"
  "typography-fx-palette-overlay.png"
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
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        return 0
    pos = 8
    w = h = 0
    bit_depth = color_type = 0
    idat: list[bytes] = []
    while pos < len(data):
        if pos + 8 > len(data):
            break
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        pos += 4
        ctype = data[pos : pos + 4]
        pos += 4
        chunk = data[pos : pos + length]
        pos += length + 4
        if ctype == b"IHDR":
            w, h, bit_depth, color_type = struct.unpack(">IIBB", chunk[:10])
        elif ctype == b"IDAT":
            idat.append(chunk)
        elif ctype == b"IEND":
            break
    if not idat or w == 0 or h == 0:
        return 0
    raw = zlib.decompress(b"".join(idat))
    bpp = {0: 1, 2: 3, 3: 1, 4: 4, 6: 4}.get(color_type, 4)
    stride = w * bpp + 1
    colors: set[tuple[int, ...]] = set()
    off = 0
    for _y in range(h):
        off += 1
        row = raw[off : off + w * bpp]
        off += w * bpp
        step = bpp
        for x in range(0, len(row), step):
            colors.add(tuple(row[x : x + step]))
        if len(colors) > 512:
            return len(colors)
    return len(colors)

errors = []
for name in required_names:
    p = png_dir / name
    if not p.is_file():
        errors.append(f"missing {p}")
        continue
    size = p.stat().st_size
    if size < min_bytes:
        errors.append(f"{name}: {size} bytes < {min_bytes}")
    uc = png_unique_colors(p)
    if uc < min_colors:
        errors.append(f"{name}: unique_colors={uc} < {min_colors}")

if errors:
    for e in errors:
        print(f"world-studio-typography-fx-animation completion gate: {e}", file=sys.stderr)
    sys.exit(1)

manifest.parent.mkdir(parents=True, exist_ok=True)
lines = [
    "{",
    '  "timestamp": "",',
    '  "native_only": true,',
    '  "paths": [',
]
for name in required_names:
    rel = f"docs/demo/media/native-verticals/png/{name}"
    lines.append(f'    "{rel}",')
lines += [
    "  ],",
    '  "pngs": [',
]
for name in required_names:
    rel = f"docs/demo/media/native-verticals/png/{name}"
    lines.append(f'    "{rel}",')
lines += ["  ]", "}"]
manifest.write_text("\n".join(lines) + "\n", encoding="utf-8")
print("world-studio-typography-fx-animation completion gate: OK")
PY
