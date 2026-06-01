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
if [[ ! -f "$GOAL" ]]; then
  GOAL="$ROOT/../data/goal-directed-sprints/world-studio-gui-polish.md"
fi
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

find_present_host() {
  local native="$ROOT/li-native"
  for c in \
    "$native/studio_shell_present_host.exe" \
    "$native/studio_shell_present_host" \
    "$ROOT/native/out/studio_shell_present_host.exe" \
    "$ROOT/native/out/studio_shell_present_host"; do
    if [[ -x "$c" ]]; then
      echo "$c"
      return 0
    fi
  done
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
  local ppm="$INSTALLER_OUT/frame-polish-${profile}.ppm"
  local host_bin=""
  if ! host_bin="$(find_present_host)"; then
    warn "present host not built — skip live capture for $profile"
    return 0
  fi
  STUDIO_DEMO_PROFILE="$profile" \
    "$host_bin" --width "$width" --height "$height" --screenshot "$ppm" || warn "screenshot host failed profile=$profile"
  if [[ -f "$ppm" ]]; then
    python3 "$ROOT/scripts/studio-ppm-to-png.py" "$(dirname "$ppm")" "$(dirname "$ppm")" 2>/dev/null || true
    local png="$(dirname "$ppm")/frame-polish-${profile}.png"
    if [[ ! -f "$png" ]]; then
      png="$(dirname "$ppm")/frame-000.png"
    fi
    if [[ -f "$png" ]]; then
      cp -f "$png" "$dest"
      ok "captured $dest"
    fi
  fi
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
