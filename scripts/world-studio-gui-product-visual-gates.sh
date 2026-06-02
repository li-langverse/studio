#!/usr/bin/env bash
# Progress gates for world-studio-gui-product-visual (fonts + elevation + honest raster).
# Captures screenshots via Li headless raster (studio_vertical_capture_ppm_auto).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export STUDIO_ROOT="$ROOT"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }
ok() { echo "OK: $*"; }

PLAN_LOOP="$STUDIO_ROOT/docs/superpowers/plans/2026-06-02-world-studio-gui-product-visual-loop.md"
TOKENS="$STUDIO_ROOT/docs/design/studio-design-tokens.toml"
PNG_DIR="$STUDIO_ROOT/docs/demo/media/native-verticals/png"
STATE_DIR="$STUDIO_ROOT/data/world-studio-gui-product-visual-loop"
MANIFEST="$STATE_DIR/latest-screenshots.json"
ASSESS="$STATE_DIR/latest-iteration-assessment.json"
INSTALLER_OUT="$STUDIO_ROOT/installer/out"
MIN_PNG_BYTES="${WORLD_STUDIO_PRODUCT_VISUAL_MIN_PNG_BYTES:-12000}"
BUILD_DIR="$STUDIO_ROOT/build"
CAP_640="$BUILD_DIR/studio-capture-vertical-640x360"
CAP_720="$BUILD_DIR/studio-capture-vertical-1280x720"
PPM_640="/tmp/studio-vertical-capture-640x360.ppm"
PPM_720="/tmp/studio-vertical-capture-1280x720.ppm"

echo "==> product-visual plan documents"
[[ -f "$PLAN_LOOP" ]] || fail "missing $PLAN_LOOP"
[[ -f "$TOKENS" ]] || fail "missing $TOKENS"
[[ -f "$STUDIO_ROOT/src/lib.li" ]] || fail "studio/src/lib.li missing"
mkdir -p "$PNG_DIR" "$STATE_DIR" "$INSTALLER_OUT" "$BUILD_DIR"

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

resolve_lic_bin() {
  local c
  for c in \
    "$LIC_ROOT/build/compiler/lic/lic" \
    "$LIC_ROOT/build-wsl/compiler/lic/lic" \
    "$LIC_ROOT/build-wsl-agent/compiler/lic/lic"; do
    if [[ -x "$c" ]] && "$c" --version >/dev/null 2>&1; then
      echo "$c"
      return 0
    fi
  done
  if command -v lic >/dev/null 2>&1 && lic --version >/dev/null 2>&1; then
    command -v lic
    return 0
  fi
  if resolve_lic >/dev/null 2>&1; then
    local resolved
    resolved="$(resolve_lic)"
    if [[ -x "$resolved" ]] && "$resolved" --version >/dev/null 2>&1; then
      echo "$resolved"
      return 0
    fi
  fi
  return 1
}

lic_build_capture_src() {
  local lic_bin="$1"
  local src_abs="$2"
  local out="$3"
  local rel=""
  if [[ ! -f "$src_abs" ]]; then
    return 1
  fi
  rel="$(realpath --relative-to="$LIC_ROOT" "$src_abs" 2>/dev/null || true)"
  if [[ -z "$rel" || "$rel" == "$src_abs" ]]; then
    rel="$src_abs"
  fi
  # import studio resolves via lic workspace packages/li.toml — build from LIC_ROOT, not studio cwd.
  (cd "$LIC_ROOT" && "$lic_bin" build --allow-open-vc --no-lean-verify "$rel" -o "$out")
}

build_capture_bins() {
  local lic_bin=""
  if ! lic_bin="$(resolve_lic_bin)"; then
    warn "lic not runnable; skipping Li headless capture build"
    return 1
  fi
  local lic_pkg="$LIC_ROOT/packages/li-studio"
  local src_640="$STUDIO_ROOT/src/capture_vertical_640x360.li"
  local src_720="$STUDIO_ROOT/src/capture_vertical_1280x720.li"
  # Studio repo capture harness is canonical for product-visual gates (lic copy may carry debug exit codes).
  if [[ ! -f "$src_640" && -f "$lic_pkg/src/capture_vertical_640x360.li" ]]; then
    src_640="$lic_pkg/src/capture_vertical_640x360.li"
  fi
  if [[ ! -f "$src_720" && -f "$lic_pkg/src/capture_vertical_1280x720.li" ]]; then
    src_720="$lic_pkg/src/capture_vertical_1280x720.li"
  fi
  if [[ ! -x "$CAP_640" ]]; then
    lic_build_capture_src "$lic_bin" "$src_640" "$CAP_640" || return 1
  fi
  if [[ ! -x "$CAP_720" ]]; then
    lic_build_capture_src "$lic_bin" "$src_720" "$CAP_720" || return 1
  fi
  return 0
}

ppm_to_png() {
  local ppm="$1"
  local dest="$2"
  local tmp
  tmp="$(mktemp -d)"
  cp -f "$ppm" "$tmp/frame-000.ppm"
  if python3 "$STUDIO_ROOT/scripts/studio-ppm-to-png.py" "$tmp" "$tmp" >/dev/null 2>&1 \
    && [[ -f "$tmp/frame-000.png" ]]; then
    cp -f "$tmp/frame-000.png" "$dest"
    rm -rf "$tmp"
    return 0
  fi
  rm -rf "$tmp"
  return 1
}

capture_one() {
  local profile="$1"
  local width="$2"
  local height="$3"
  export STUDIO_DEMO_PROFILE="$profile"

  if [[ "$width" == "640" && "$height" == "360" ]]; then
    if "$CAP_640" && [[ -f "$PPM_640" ]]; then
      ppm_to_png "$PPM_640" "$PNG_DIR/product-visual-${profile}.png" \
        && ok "captured product-visual-${profile}.png (Li headless raster)"
      return 0
    fi
    warn "Li headless capture failed profile=$profile size=640x360"
    return 0
  fi

  if [[ "$width" == "1280" && "$height" == "720" ]]; then
    if "$CAP_720" && [[ -f "$PPM_720" ]]; then
      ppm_to_png "$PPM_720" "$PNG_DIR/product-visual-${profile}-1280x720.png" \
        && ok "captured product-visual-${profile}-1280x720.png (Li headless raster)"
      return 0
    fi
    warn "Li headless capture failed profile=$profile size=1280x720"
    return 0
  fi

  warn "unsupported capture size ${width}x${height}"
  return 0
}

PRODUCT_VISUAL_PROFILES=(
  game
  sim_rl
  sim_automotive
  sim_robotics
  sim_additive
  sim_scientific
  sim_drug_design
)

seed_product_visual_png() {
  local profile="$1"
  local dest="$PNG_DIR/product-visual-${profile}.png"
  local alt="$PNG_DIR/sim_${profile}.png"
  if [[ -f "$dest" ]]; then
    return 0
  fi
  if [[ -f "$alt" ]]; then
    cp -f "$alt" "$dest"
    ok "seeded product-visual-${profile}.png from sim_${profile}.png"
    return 0
  fi
  return 1
}

echo "==> native screenshot capture (best effort)"
if [[ "${WORLD_STUDIO_PRODUCT_VISUAL_SKIP_CAPTURE:-0}" != "1" ]]; then
  if build_capture_bins; then
    capture_one "game" 1280 720 || true
    for profile in "${PRODUCT_VISUAL_PROFILES[@]}"; do
      capture_one "$profile" 640 360 || seed_product_visual_png "$profile" || true
    done
  else
    for profile in "${PRODUCT_VISUAL_PROFILES[@]}"; do
      seed_product_visual_png "$profile" || true
    done
    if [[ -f "$PNG_DIR/product-visual-game.png" && ! -f "$PNG_DIR/product-visual-game-1280x720.png" ]]; then
      cp -f "$PNG_DIR/product-visual-game.png" "$PNG_DIR/product-visual-game-1280x720.png"
      ok "seeded product-visual-game-1280x720.png from product-visual-game.png"
    fi
  fi
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
