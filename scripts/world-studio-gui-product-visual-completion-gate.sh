#!/usr/bin/env bash
# Completion gate: all P0..P5 todos done + screenshot set present.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "OK: $*"; }

LOOP="$ROOT/docs/superpowers/plans/2026-06-02-world-studio-gui-product-visual-loop.md"
SHOTS="$ROOT/data/world-studio-gui-product-visual-loop/latest-screenshots.json"

[[ -f "$LOOP" ]] || fail "missing plan loop $LOOP"

echo "==> progress gates"
bash "$ROOT/scripts/world-studio-gui-product-visual-gates.sh"

echo "==> plan todos all done"
python3 - "$LOOP" <<'PY'
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8")
todo_blocks = re.findall(
    r"^  - id: (wsv-w[0-9]+-[a-z0-9_-]+)\n(?:^    .+\n)+?^    status: (\w+)\n",
    text,
    flags=re.M,
)
pending = [(i, s) for (i, s) in todo_blocks if s != "done"]
if pending:
    raise SystemExit("FAIL: pending todos: " + ", ".join(f"{i}={s}" for i, s in pending))
print("OK: all wsv todos done")
PY

echo "==> screenshots manifest + files"
[[ -f "$SHOTS" ]] || fail "missing $SHOTS"
python3 - "$SHOTS" "$ROOT" <<'PY'
import json, sys
from pathlib import Path
shots = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
root = Path(sys.argv[2])

paths = []
for key in ("pngs", "screenshots"):
    v = shots.get(key, [])
    if isinstance(v, list):
        if key == "pngs":
            paths.extend([p for p in v if isinstance(p, str)])
        else:
            paths.extend([s.get("path") for s in v if isinstance(s, dict) and isinstance(s.get("path"), str)])

missing = [p for p in paths if not (root / p).is_file()]
if missing:
    raise SystemExit("FAIL: missing screenshot files: " + ", ".join(missing[:10]))

need = [p for p in paths if "product-visual-" in Path(p).name and p.endswith(".png")]
if len(need) < 7:
    raise SystemExit(f"FAIL: expected >=7 product-visual PNGs, got {len(need)}")

print("OK: screenshots present")
PY

ok "world-studio-gui-product-visual-completion-gate"

