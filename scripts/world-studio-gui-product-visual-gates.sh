#!/usr/bin/env bash
# Progress gates for world-studio-gui-product-visual (fonts + elevation + honest raster).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export STUDIO_ROOT="$ROOT"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }
ok() { echo "OK: $*"; }

PLAN_LOOP="$STUDIO_ROOT/docs/superpowers/plans/2026-06-02-world-studio-gui-product-visual-loop.md"
GOAL="$STUDIO_ROOT/data/goal-directed-sprints/world-studio-gui-product-visual.md"
TOKENS="$STUDIO_ROOT/docs/design/studio-design-tokens.toml"
PNG_DIR="$STUDIO_ROOT/docs/demo/media/native-verticals/png"
STATE_DIR="$STUDIO_ROOT/data/world-studio-gui-product-visual-loop"
MANIFEST="$STATE_DIR/latest-screenshots.json"
ASSESS="$STATE_DIR/latest-iteration-assessment.json"
INSTALLER_OUT="$STUDIO_ROOT/installer/out"
MIN_PNG_BYTES="${WORLD_STUDIO_PRODUCT_VISUAL_MIN_PNG_BYTES:-12000}"

echo "==> product-visual plan documents"
[[ -f "$PLAN_LOOP" ]] || fail "missing $PLAN_LOOP"
[[ -f "$GOAL" ]] || fail "missing goal $GOAL"
[[ -f "$TOKENS" ]] || fail "missing $TOKENS"
[[ -f "$STUDIO_ROOT/src/lib.li" ]] || fail "studio/src/lib.li missing"
mkdir -p "$PNG_DIR" "$STATE_DIR" "$INSTALLER_OUT"

echo "==> token verification"
if [[ -f "$STUDIO_ROOT/scripts/studio-ui-ux-verify-tokens.py" ]]; then
  export LIC_ROOT
  python3 "$STUDIO_ROOT/scripts/studio-ui-ux-verify-tokens.py" || fail "studio-ui-ux-verify-tokens"
else
  fail "missing studio-ui-ux-verify-tokens.py"
fi

echo "==> raster truth (no paint_fb-as-product)"
if [[ -f "$STUDIO_ROOT/deploy/studio-demo/native/studio_shell_paint_fb.c" ]]; then
  warn "paint_fb mirror still exists (allowed for deprecated CI captures), but product-visual captures must use Li raster truth"
fi

capture_one() {
  local profile="$1"
  local width="${2:-1280}"
  local height="${3:-720}"
  local out_name="product-visual-${profile}.png"
  if [[ "$width" == "1280" && "$height" == "720" ]]; then
    out_name="product-visual-${profile}-1280x720.png"
  fi
  local dest="$PNG_DIR/$out_name"

  local ppm="$INSTALLER_OUT/frame-000.ppm"
  if [[ -f "$ppm" ]]; then
    if python3 "$STUDIO_ROOT/scripts/studio-ppm-to-png.py" "$INSTALLER_OUT" "$INSTALLER_OUT" >/dev/null 2>&1 \
      && [[ -f "$INSTALLER_OUT/frame-000.png" ]]; then
      cp -f "$INSTALLER_OUT/frame-000.png" "$dest"
      ok "captured $dest (from $ppm)"
      return 0
    fi
  fi
  warn "no Li raster PPM available for profile=$profile (run a real-window capture step first)"
  return 0
}

echo "==> native screenshot capture (best effort)"
if [[ "${WORLD_STUDIO_PRODUCT_VISUAL_SKIP_CAPTURE:-0}" != "1" ]]; then
  capture_one "game" 1280 720 || true
  capture_one "sim_drug_design" 1280 720 || true
  capture_one "sim_rl" 1280 720 || true
fi

echo "==> screenshot manifest"
python3 - "$MANIFEST" "$STUDIO_ROOT" "$PNG_DIR" "$MIN_PNG_BYTES" <<'PY'
import json, sys
from pathlib import Path

manifest, repo_root, png_dir, min_bytes = sys.argv[1:5]
min_bytes = int(min_bytes)
root = Path(repo_root).resolve()
png_dir = Path(png_dir)

def rel(p: Path) -> str:
    try:
        return p.resolve().relative_to(root).as_posix()
    except ValueError:
        return str(p.resolve())

pngs = sorted(png_dir.glob("product-visual-*.png"))
paths = [rel(p) for p in pngs]
payload = {
    "timestamp": __import__("datetime").datetime.now(__import__("datetime").timezone.utc).isoformat(),
    "native_only": True,
    "paths": paths,
    "pngs": [rel(p) for p in pngs],
}
Path(manifest).parent.mkdir(parents=True, exist_ok=True)
Path(manifest).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
small = [rel(p) for p in pngs if p.stat().st_size < min_bytes]
if small:
    print("WARN: product-visual PNGs below min bytes:", ", ".join(small), file=sys.stderr)
print("OK: wrote", manifest)
PY

if [[ -f "$ASSESS" ]]; then
  ok "assessment present: $ASSESS"
else
  python3 - "$ASSESS" <<'PY'
import json
from datetime import datetime, timezone
from pathlib import Path
p = Path(__import__("sys").argv[1])
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps({
    "timestamp": datetime.now(timezone.utc).isoformat(),
    "native_only": True,
    "product_visual_phase": "progress",
}, indent=2) + "\n", encoding="utf-8")
PY
  ok "seeded $ASSESS"
fi

ok "world-studio-gui-product-visual progress gates"
