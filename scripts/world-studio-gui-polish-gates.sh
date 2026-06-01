#!/usr/bin/env bash
# Progress gates for world-studio-gui-polish (visual polish, screenshot manifest).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"

fail() { echo "FAIL: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }
ok() { echo "OK: $*"; }

PLAN_LOOP="$ROOT/docs/superpowers/plans/2026-05-31-world-studio-gui-polish-loop.md"
GOAL="$ROOT/data/goal-directed-sprints/world-studio-gui-polish.md"
TOKENS="$ROOT/docs/design/studio-design-tokens.toml"
POLISH_DIR="$ROOT/docs/demo/media/native-verticals/png"
STATE_DIR="$ROOT/data/world-studio-gui-polish-loop"
MANIFEST="$STATE_DIR/latest-screenshots.json"
ASSESS="$STATE_DIR/latest-iteration-assessment.json"
INSTALLER_OUT="$ROOT/installer/out"
MIN_POLISH_BYTES="${WORLD_STUDIO_POLISH_MIN_PNG_BYTES:-12000}"

echo "==> polish plan documents"
[[ -f "$PLAN_LOOP" ]] || fail "missing $PLAN_LOOP"
[[ -f "$GOAL" ]] || fail "missing goal $GOAL"
[[ -f "$TOKENS" ]] || fail "missing $TOKENS"
[[ -f "$ROOT/src/lib.li" ]] || fail "studio/src/lib.li missing"
mkdir -p "$POLISH_DIR" "$STATE_DIR" "$INSTALLER_OUT"

echo "==> token verification"
if [[ -f "$ROOT/scripts/studio-ui-ux-verify-tokens.py" ]]; then
  export LIC_ROOT
  python3 "$ROOT/scripts/studio-ui-ux-verify-tokens.py" || fail "studio-ui-ux-verify-tokens"
else
  fail "missing studio-ui-ux-verify-tokens.py"
fi

find_verticals_host() {
  local native="$ROOT/deploy/studio-demo/native"
  for c in \
    "$native/studio_verticals_present_host.exe" \
    "$native/studio_verticals_present_host" \
    "$ROOT/li-native/studio_verticals_present_host.exe" \
    "$ROOT/li-native/studio_verticals_present_host"; do
    if [[ -x "$c" ]]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

build_verticals_host() {
  local native="$ROOT/deploy/studio-demo/native"
  local bin="$native/studio_verticals_present_host"
  if [[ -x "$bin" ]]; then
    echo "$bin"
    return 0
  fi
  if [[ ! -f "$native/studio_shell_paint_fb.c" ]]; then
    return 1
  fi
  if command -v cc >/dev/null 2>&1; then
    cc -std=c11 -Wall -Wextra -O2 \
      "$native/studio_shell_paint_fb.c" \
      "$native/studio_verticals_present_host.c" \
      -o "$bin" 2>/dev/null || return 1
    chmod +x "$bin" 2>/dev/null || true
    echo "$bin"
    return 0
  fi
  if [[ -x "$native/native-sdl-build.sh" && -f "$native/studio_verticals_present_host.c" ]]; then
    bash "$native/native-sdl-build.sh" "$native/studio_verticals_present_host.c" "$bin" 2>/dev/null || return 1
    echo "$bin"
    return 0
  fi
  return 1
}

capture_profile_png() {
  local profile="$1"
  local width="${2:-1280}"
  local height="${3:-720}"
  local out_name="polish-${profile}.png"
  if [[ "$width" == "1280" && "$height" == "720" && "$profile" == "game" ]]; then
    out_name="polish-game-1280x720.png"
  fi
  local dest="$POLISH_DIR/$out_name"
  local tmp
  tmp="$(mktemp -d)"
  local host_bin=""
  if ! host_bin="$(find_verticals_host)"; then
    host_bin="$(build_verticals_host)" || true
  fi
  if [[ -z "$host_bin" || ! -x "$host_bin" ]]; then
    warn "verticals present host not built — skip live capture for $profile"
    rm -rf "$tmp"
    return 0
  fi
  if STUDIO_DEMO_PROFILE="$profile" \
    "$host_bin" --slug "$profile" --width "$width" --height "$height" --out "$tmp" 2>/dev/null \
    | grep -q '"native_pixels":1'; then
    if python3 "$ROOT/scripts/studio-ppm-to-png.py" "$tmp" "$tmp" >/dev/null 2>&1 \
      && [[ -f "$tmp/frame-000.png" ]]; then
      cp -f "$tmp/frame-000.png" "$dest"
      cp -f "$tmp/frame-000.png" "$INSTALLER_OUT/studio-screenshot-iteration-${WORLD_STUDIO_POLISH_ITERATION:-0}.png" 2>/dev/null || true
      ok "captured $dest"
    fi
  else
    warn "verticals capture failed profile=$profile"
  fi
  rm -rf "$tmp"
}

echo "==> native screenshot capture (best effort)"
if [[ "${WORLD_STUDIO_POLISH_SKIP_CAPTURE:-0}" != "1" ]]; then
  capture_profile_png "game" 1280 720 || true
  capture_profile_png "sim_drug_design" 1280 720 || true
  capture_profile_png "sim_rl" 1280 720 || true
  iter_n="${WORLD_STUDIO_POLISH_ITERATION:-0}"
  if [[ -f "$INSTALLER_OUT/frame-000.png" ]]; then
    cp -f "$INSTALLER_OUT/frame-000.png" "$INSTALLER_OUT/studio-screenshot-iteration-${iter_n}.png" 2>/dev/null || true
  fi
fi

echo "==> screenshot manifest"
python3 - "$MANIFEST" "$POLISH_DIR" "$INSTALLER_OUT" "$MIN_POLISH_BYTES" <<'PY'
import json, os, sys
from pathlib import Path

manifest, polish_dir, installer_out, min_bytes = sys.argv[1:5]
min_bytes = int(min_bytes)
polish = Path(polish_dir)
installer = Path(installer_out)
paths: list[str] = []
for p in sorted(polish.glob("polish-*.png")):
    paths.append(str(p.resolve()))
for p in sorted(installer.glob("studio-screenshot-iteration-*.png")):
    paths.append(str(p.resolve()))
baseline = installer / "studio-screenshot-polish-baseline.png"
if baseline.is_file():
    paths.insert(0, str(baseline.resolve()))
payload = {
    "timestamp": __import__("datetime").datetime.now(__import__("datetime").timezone.utc).isoformat(),
    "native_only": True,
    "paths": paths,
    "polish_pngs": [str(p) for p in polish.glob("polish-*.png")],
}
Path(manifest).parent.mkdir(parents=True, exist_ok=True)
Path(manifest).write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
small = [p for p in payload["polish_pngs"] if Path(p).stat().st_size < min_bytes]
if small:
    print("WARN: polish PNGs below min bytes:", ", ".join(small), file=sys.stderr)
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
    "polish_phase": "progress",
}, indent=2) + "\n", encoding="utf-8")
PY
  ok "seeded $ASSESS"
fi

ok "world-studio-gui-polish progress gates"
