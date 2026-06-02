#!/usr/bin/env bash
# Progress gates for world-studio-gui-product-visual (fonts/elevation/honest raster).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"

fail() { echo "FAIL: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }
ok() { echo "OK: $*"; }

PLAN_LOOP="$ROOT/docs/superpowers/plans/2026-06-02-world-studio-gui-product-visual-loop.md"
TOKENS="$ROOT/docs/design/studio-design-tokens.toml"
PNG_DIR="$ROOT/docs/demo/media/native-verticals/png"
STATE_DIR="$ROOT/data/world-studio-gui-product-visual-loop"
MANIFEST="$STATE_DIR/latest-screenshots.json"
ASSESS="$STATE_DIR/latest-iteration-assessment.json"

CAP_640="$ROOT/build/studio-capture-vertical-640x360"
CAP_720="$ROOT/build/studio-capture-vertical-1280x720"
PPM_640="/tmp/studio-vertical-capture-640x360.ppm"
PPM_720="/tmp/studio-vertical-capture-1280x720.ppm"

echo "==> product-visual plan documents"
[[ -f "$PLAN_LOOP" ]] || fail "missing $PLAN_LOOP"
[[ -f "$TOKENS" ]] || fail "missing $TOKENS"
[[ -f "$ROOT/src/lib.li" ]] || fail "studio/src/lib.li missing"
mkdir -p "$PNG_DIR" "$STATE_DIR" "$ROOT/build"

echo "==> token verification"
if [[ -f "$ROOT/scripts/studio-ui-ux-verify-tokens.py" ]]; then
  export LIC_ROOT
  python3 "$ROOT/scripts/studio-ui-ux-verify-tokens.py" || fail "studio-ui-ux-verify-tokens"
else
  fail "missing studio-ui-ux-verify-tokens.py"
fi

build_capture_bins() {
  if ! command -v lic >/dev/null 2>&1; then
    warn "lic not on PATH; skipping Li capture build"
    return 1
  fi
  if [[ ! -x "$CAP_640" ]]; then
    lic build --allow-open-vc --no-lean-verify "$ROOT/src/capture_vertical_640x360.li" -o "$CAP_640" \
      || return 1
  fi
  if [[ ! -x "$CAP_720" ]]; then
    lic build --allow-open-vc --no-lean-verify "$ROOT/src/capture_vertical_1280x720.li" -o "$CAP_720" \
      || return 1
  fi
  return 0
}

ppm_to_png() {
  local ppm="$1"
  local dest="$2"
  local tmp
  tmp="$(mktemp -d)"
  cp -f "$ppm" "$tmp/frame-000.ppm"
  if python3 "$ROOT/scripts/studio-ppm-to-png.py" "$tmp" "$tmp" >/dev/null 2>&1 \
    && [[ -f "$tmp/frame-000.png" ]]; then
    cp -f "$tmp/frame-000.png" "$dest"
    rm -rf "$tmp"
    return 0
  fi
  rm -rf "$tmp"
  return 1
}

capture_profile() {
  local slug="$1"
  export STUDIO_DEMO_PROFILE="$slug"
  if [[ -x "$CAP_640" ]]; then
    if "$CAP_640" && [[ -f "$PPM_640" ]]; then
      ppm_to_png "$PPM_640" "$PNG_DIR/product-visual-${slug}.png" \
        && ok "captured $PNG_DIR/product-visual-${slug}.png (Li pixels)"
    else
      warn "Li 640x360 capture failed slug=$slug"
    fi
  fi
  if [[ -x "$CAP_720" ]]; then
    if "$CAP_720" && [[ -f "$PPM_720" ]]; then
      ppm_to_png "$PPM_720" "$PNG_DIR/product-visual-${slug}-1280x720.png" \
        && ok "captured $PNG_DIR/product-visual-${slug}-1280x720.png (Li pixels)"
    else
      warn "Li 1280x720 capture failed slug=$slug"
    fi
  fi
}

echo "==> native screenshot capture (Li raster, best effort)"
if build_capture_bins; then
  capture_profile "game" || true
  capture_profile "sim_drug_design" || true
  capture_profile "sim_rl" || true
else
  warn "Li capture bins not available; skipping captures"
fi

echo "==> screenshot manifest"
python3 - "$MANIFEST" "$ROOT" "$PNG_DIR" <<'PY'
import json, sys
from pathlib import Path
from datetime import datetime, timezone

manifest, repo_root, png_dir = sys.argv[1:4]
root = Path(repo_root).resolve()
png = Path(png_dir)

def rel(p: Path) -> str:
    try:
        return p.resolve().relative_to(root).as_posix()
    except ValueError:
        return str(p.resolve())

paths = []
for p in sorted(png.glob("product-visual-*.png")):
    paths.append(rel(p))

payload = {
    "timestamp": datetime.now(timezone.utc).isoformat(),
    "native_only": True,
    "paths": paths,
}
Path(manifest).parent.mkdir(parents=True, exist_ok=True)
Path(manifest).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print("OK: wrote", manifest)
PY

echo "==> iteration assessment"
python3 - "$ASSESS" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path

p = Path(sys.argv[1])
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps({
    "timestamp": datetime.now(timezone.utc).isoformat(),
    "native_only": True,
    "todo": "wsv-w0-single-pixel-truth",
    "notes": [
        "Gates capture screenshots via Li studio_vertical_capture_ppm_auto (headless raster), not C paint_fb mirror.",
    ],
}, indent=2) + "\n", encoding="utf-8")
print("OK: wrote", p)
PY

ok "world-studio-gui-product-visual progress gates"

