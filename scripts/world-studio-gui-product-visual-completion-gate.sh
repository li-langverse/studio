#!/usr/bin/env bash
# Completion gate for world-studio-gui-product-visual.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "OK: $*"; }

STATE_DIR="$ROOT/data/world-studio-gui-product-visual-loop"
MANIFEST="$STATE_DIR/latest-screenshots.json"
ASSESS="$STATE_DIR/latest-iteration-assessment.json"

[[ -x "$ROOT/scripts/world-studio-gui-product-visual-gates.sh" ]] || chmod +x "$ROOT/scripts/world-studio-gui-product-visual-gates.sh"
bash "$ROOT/scripts/world-studio-gui-product-visual-gates.sh"

[[ -f "$MANIFEST" ]] || fail "missing $MANIFEST"
[[ -f "$ASSESS" ]] || fail "missing $ASSESS"

python3 - "$MANIFEST" "$ROOT" <<'PY'
import json, sys
from pathlib import Path

manifest, repo_root = sys.argv[1:3]
root = Path(repo_root).resolve()
d = json.loads(Path(manifest).read_text(encoding="utf-8"))
paths = d.get("paths", [])
if not d.get("native_only", False):
    raise SystemExit("manifest: native_only must be true")
need = [
    "docs/demo/media/native-verticals/png/product-visual-game.png",
    "docs/demo/media/native-verticals/png/product-visual-game-1280x720.png",
]
missing = [p for p in need if p not in paths or not (root / p).is_file()]
if missing:
    raise SystemExit("missing required screenshots: " + ", ".join(missing))
print("OK: completion screenshots present")
PY

ok "world-studio-gui-product-visual completion gate"

