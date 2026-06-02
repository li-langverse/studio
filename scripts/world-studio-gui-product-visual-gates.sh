#!/usr/bin/env bash
# Progress gates for the GUI product-visual sprint (fonts + elevation + honest raster).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }
ok() { echo "OK: $*"; }

LOOP="$ROOT/docs/superpowers/plans/2026-06-02-world-studio-gui-product-visual-loop.md"
ASSESS="$ROOT/data/world-studio-gui-product-visual-loop/latest-iteration-assessment.json"
SHOTS="$ROOT/data/world-studio-gui-product-visual-loop/latest-screenshots.json"

echo "==> plan loop present"
[[ -f "$LOOP" ]] || fail "missing plan loop $LOOP"

echo "==> native-only policy"
if [[ -f "$ROOT/.cursor/rules/li-studio-demo-native-only.mdc" ]]; then
  ok "native-only rule present"
else
  warn "native-only rule file missing (expected .cursor/rules/li-studio-demo-native-only.mdc)"
fi

echo "==> forbid marketing HTML as product runtime"
if python3 - "$ROOT" <<'PY'; then
import sys
from pathlib import Path
root = Path(sys.argv[1])
src = root / "src"
if not src.is_dir():
    raise SystemExit(0)
for p in src.rglob("*"):
    if p.is_file() and p.suffix in (".ts", ".tsx", ".js", ".mjs", ".li", ".md"):
        t = p.read_text(encoding="utf-8", errors="ignore")
        if "deploy/studio-demo/01-studio-workspace.html" in t or "01-studio-workspace.html" in t:
            raise SystemExit(1)
raise SystemExit(0)
PY
  ok "no src references to marketing HTML mocks"
else
  fail "src references marketing HTML mock (forbidden as product runtime)"
fi

echo "==> raster truth (no C paint_fb mirror in capture path)"
CAP="$ROOT/scripts/studio-verticals-capture-native.sh"
[[ -f "$CAP" ]] || fail "missing $CAP"
if grep -q 'studio_shell_paint_fb.c' "$CAP"; then
  fail "capture script still references studio_shell_paint_fb.c (must be Li raster truth path)"
fi
ok "capture script does not build C paint_fb mirror"

echo "==> typography + elevation sanity (smokes exist)"
for f in \
  "$ROOT/li-tests/smoke/studio_polish_w1_glyphs.li" \
  "$ROOT/li-tests/smoke/studio_polish_w4_shadows_spacing.li"; do
  [[ -f "$f" ]] || fail "missing smoke $f"
done
ok "product-visual-relevant smokes present"

echo "==> screenshots/assessment json presence (soft gate; written by iteration)"
if [[ -f "$ASSESS" ]]; then
  python3 - "$ASSESS" <<'PY' || fail "latest-iteration-assessment.json invalid"
import json, sys
from pathlib import Path
p = Path(sys.argv[1])
d = json.loads(p.read_text(encoding="utf-8"))
assert d.get("native_only", True) is True
PY
  ok "latest-iteration-assessment.json present"
else
  warn "missing $ASSESS (expected after iteration)"
fi
if [[ -f "$SHOTS" ]]; then
  python3 - "$SHOTS" <<'PY' || fail "latest-screenshots.json invalid"
import json, sys
from pathlib import Path
d = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert isinstance(d.get("screenshots", []), list)
assert isinstance(d.get("pngs", []), list)
PY
  ok "latest-screenshots.json present"
else
  warn "missing $SHOTS (expected after iteration)"
fi

ok "world-studio-gui-product-visual-gates"

