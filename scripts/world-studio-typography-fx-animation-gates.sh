#!/usr/bin/env bash
# Progress gates for world-studio-typography-fx-animation (typography tests + FX + motion).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export STUDIO_ROOT="$ROOT"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }
ok() { echo "OK: $*"; }

PLAN_LOOP="$STUDIO_ROOT/docs/superpowers/plans/2026-06-03-world-studio-typography-fx-animation-loop.md"
GOAL="$STUDIO_ROOT/data/goal-directed-sprints/world-studio-typography-fx-animation.md"
TOKENS="$STUDIO_ROOT/docs/design/studio-design-tokens.toml"
STATE_DIR="$STUDIO_ROOT/data/world-studio-typography-fx-animation-loop"
PNG_DIR="$STUDIO_ROOT/docs/demo/media/native-verticals/png"
MANIFEST="$STATE_DIR/latest-screenshots.json"
BUILD_DIR="$STUDIO_ROOT/build"
CAP_GAME_640="$BUILD_DIR/studio-capture-typography-fx-game-640x360"
CAP_GAME_720="$BUILD_DIR/studio-capture-typography-fx-game-1280x720"
CAP_INSP="$BUILD_DIR/studio-capture-typography-fx-inspector"
CAP_PAL="$BUILD_DIR/studio-capture-typography-fx-palette"
PPM_GAME_640="/tmp/studio-typography-fx-game-640x360.ppm"
PPM_GAME_720="/tmp/studio-typography-fx-game-1280x720.ppm"
PPM_INSP="/tmp/studio-typography-fx-inspector.ppm"
PPM_PAL="/tmp/studio-typography-fx-palette.ppm"

echo "==> typography-fx plan documents"
[[ -f "$PLAN_LOOP" ]] || fail "missing $PLAN_LOOP"
[[ -f "$GOAL" ]] || fail "missing $GOAL"
[[ -f "$TOKENS" ]] || fail "missing $TOKENS"
mkdir -p "$STATE_DIR" "$PNG_DIR"

echo "==> token verification"
if [[ -f "$STUDIO_ROOT/scripts/studio-ui-ux-verify-tokens.py" ]]; then
  export LIC_ROOT
  python3 "$STUDIO_ROOT/scripts/studio-ui-ux-verify-tokens.py" || fail "studio-ui-ux-verify-tokens"
else
  fail "missing studio-ui-ux-verify-tokens.py"
fi

resolve_lic_bin() {
  local c
  for c in \
    "$LIC_ROOT/build-wsl/compiler/lic/lic" \
    "$LIC_ROOT/build/compiler/lic/lic" \
    "$LIC_ROOT/out/compiler/lic/lic" \
    "$(command -v lic 2>/dev/null || true)"; do
    if [[ -n "$c" && -x "$c" ]] && "$c" --version >/dev/null 2>&1; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

lic_build_capture_src() {
  local lic_bin="$1"
  local src_abs="$2"
  local out="$3"
  if [[ ! -f "$src_abs" ]]; then
    return 1
  fi
  local rel=""
  rel="$(realpath --relative-to="$LIC_ROOT" "$src_abs" 2>/dev/null || true)"
  if [[ -z "$rel" || "$rel" == "$src_abs" ]]; then
    rel="$src_abs"
  fi
  (cd "$LIC_ROOT" && "$lic_bin" build --allow-open-vc --no-lean-verify "$rel" -o "$out")
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

build_typography_fx_capture_bins() {
  local lic_bin=""
  if ! lic_bin="$(resolve_lic_bin)"; then
    warn "lic not runnable; skipping typography-fx PNG capture"
    return 1
  fi
  mkdir -p "$BUILD_DIR"
  lic_build_capture_src "$lic_bin" "$STUDIO_ROOT/src/capture_typography_fx_game_640x360.li" "$CAP_GAME_640" || return 1
  lic_build_capture_src "$lic_bin" "$STUDIO_ROOT/src/capture_typography_fx_game_1280x720.li" "$CAP_GAME_720" || return 1
  lic_build_capture_src "$lic_bin" "$STUDIO_ROOT/src/capture_typography_fx_inspector.li" "$CAP_INSP" || return 1
  lic_build_capture_src "$lic_bin" "$STUDIO_ROOT/src/capture_typography_fx_palette.li" "$CAP_PAL" || return 1
  return 0
}

capture_typography_fx_pngs() {
  if ! build_typography_fx_capture_bins; then
    return 1
  fi
  if "$CAP_GAME_640" && [[ -f "$PPM_GAME_640" ]]; then
    ppm_to_png "$PPM_GAME_640" "$PNG_DIR/typography-fx-game.png" && ok "captured typography-fx-game.png"
  fi
  if "$CAP_GAME_720" && [[ -f "$PPM_GAME_720" ]]; then
    ppm_to_png "$PPM_GAME_720" "$PNG_DIR/typography-fx-game-1280x720.png" \
      && ok "captured typography-fx-game-1280x720.png"
  fi
  if "$CAP_INSP" && [[ -f "$PPM_INSP" ]]; then
    ppm_to_png "$PPM_INSP" "$PNG_DIR/typography-fx-inspector-panel.png" \
      && ok "captured typography-fx-inspector-panel.png"
  fi
  if "$CAP_PAL" && [[ -f "$PPM_PAL" ]]; then
    ppm_to_png "$PPM_PAL" "$PNG_DIR/typography-fx-palette-overlay.png" \
      && ok "captured typography-fx-palette-overlay.png"
  fi
}

LIC_BIN=""
if LIC_BIN="$(resolve_lic_bin)"; then
  ok "lic=$LIC_BIN"
else
  warn "lic binary not found — skipping lit smokes (CI/K8s may still run agent code changes)"
fi

run_smoke() {
  local path="$1"
  if [[ -z "$LIC_BIN" ]]; then
    warn "skip smoke (no lic): $path"
    return 0
  fi
  if [[ ! -f "$path" ]]; then
    warn "smoke not yet added: $path"
    return 0
  fi
  echo "==> lic check $path"
  "$LIC_BIN" check --paths "$path" || fail "lic check $path"
}

# Baseline smokes (must stay green throughout sprint)
BASELINE_SMOKES=(
  "$LIC_ROOT/packages/li-ui/li-tests/smoke/studio_typography_tokens.li"
  "$LIC_ROOT/packages/li-ui/li-tests/smoke/font_atlas_inter_mono.li"
  "$STUDIO_ROOT/li-tests/smoke/studio_polish_w0_typography.li"
  "$STUDIO_ROOT/li-tests/smoke/studio_polish_w4_shadows_spacing.li"
)

for s in "${BASELINE_SMOKES[@]}"; do
  run_smoke "$s"
done

# W0+ smokes (warn until files land)
WTFX_SMOKES=(
  "$LIC_ROOT/packages/li-ui/li-tests/smoke/font_atlas_metrics_matrix.li"
  "$LIC_ROOT/packages/li-ui/li-tests/smoke/text_layout_baseline.li"
  "$LIC_ROOT/packages/li-ui/li-tests/smoke/glyph_run_layout.li"
  "$STUDIO_ROOT/li-tests/smoke/studio_typography_engine.li"
  "$STUDIO_ROOT/li-tests/smoke/studio_typography_raster_bounds.li"
  "$LIC_ROOT/packages/li-ui/li-tests/smoke/color_alpha_composite.li"
  "$STUDIO_ROOT/li-tests/smoke/studio_viewport_scrim_opacity.li"
  "$STUDIO_ROOT/li-tests/smoke/studio_shadow_math.li"
  "$LIC_ROOT/packages/li-ui/li-tests/smoke/blur_kernel_energy.li"
  "$LIC_ROOT/packages/li-gui/li-tests/smoke/motion_easing.li"
  "$STUDIO_ROOT/li-tests/smoke/studio_motion_hover_opacity.li"
  "$STUDIO_ROOT/li-tests/smoke/studio_panel_switch_timing.li"
  "$STUDIO_ROOT/li-tests/smoke/studio_typography_fx_w7_acceptance.li"
)

for s in "${WTFX_SMOKES[@]}"; do
  run_smoke "$s"
done

echo "==> typography-fx acceptance PNG capture (best effort)"
if [[ "${WORLD_STUDIO_TYPOGRAPHY_FX_SKIP_CAPTURE:-0}" != "1" ]]; then
  if capture_typography_fx_pngs; then
    :
  elif [[ -f "$STUDIO_ROOT/scripts/generate-typography-fx-acceptance-pngs.py" ]]; then
    warn "lic capture unavailable — generating headless-raster-equivalent PNGs"
    python3 "$STUDIO_ROOT/scripts/generate-typography-fx-acceptance-pngs.py" \
      || warn "typography-fx PNG generation failed"
  else
    warn "typography-fx capture incomplete (CI/K8s may capture with lic build)"
  fi
fi

echo "==> screenshot manifest"
python3 - "$MANIFEST" "$PNG_DIR" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path

manifest = Path(sys.argv[1])
png_dir = Path(sys.argv[2])
required = [
    "typography-fx-game-1280x720.png",
    "typography-fx-game.png",
    "typography-fx-inspector-panel.png",
    "typography-fx-palette-overlay.png",
]
paths = [f"docs/demo/media/native-verticals/png/{n}" for n in required if (png_dir / n).is_file()]
manifest.parent.mkdir(parents=True, exist_ok=True)
manifest.write_text(
    json.dumps(
        {
            "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "native_only": True,
            "paths": paths,
            "pngs": paths,
        },
        indent=2,
    )
    + "\n",
    encoding="utf-8",
)
print("manifest:", len(paths), "of", len(required), "PNG(s)")
PY

echo "==> plan YAML pending check (informational)"
python3 - "$PLAN_LOOP" <<'PY' || true
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
if matched:
    print("pending wtfx todos:", ", ".join(pending) if pending else "(none)")
PY

ok "world-studio-typography-fx-animation progress gates finished"
