#!/usr/bin/env bash
# Launch Li World Studio on macOS with wgpu/Metal surface env (wsg-w5-macos-wgpu).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"

PROFILE="${STUDIO_DEMO_PROFILE:-game}"
WIDTH="${STUDIO_SHELL_WIDTH:-1280}"
HEIGHT="${STUDIO_SHELL_HEIGHT:-720}"
BUILD="${STUDIO_MACOS_BUILD:-0}"
SCREENSHOT_ONLY="${STUDIO_MACOS_SCREENSHOT_ONLY:-0}"

HOST="$ROOT/deploy/studio-demo/native/studio_shell_present_host"
OUT="$ROOT/installer/out"
PPM="$OUT/frame-000.ppm"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "start-li-world-studio-macos: requires Darwin (macOS)" >&2
  exit 2
fi

chmod +x "$ROOT/scripts/build-studio-shell-present-host-macos.sh" 2>/dev/null || true
"$ROOT/scripts/build-studio-shell-present-host-macos.sh"

if [[ ! -x "$HOST" ]]; then
  echo "start-li-world-studio-macos: present host missing at $HOST" >&2
  exit 3
fi

mkdir -p "$OUT"

export STUDIO_DEMO_PROFILE="$PROFILE"
export LIG_HOST_PRESENT=1
export LIG_WGPU_SWAPCHAIN=1
export LIG_GPU_RUNNER=1
export STUDIO_SHELL_PRESENT_HOST_BIN="$HOST"

if [[ "$BUILD" == "1" ]]; then
  if [[ -x "$ROOT/scripts/start-li-world-studio.ps1" ]]; then
    powershell -NoProfile -ExecutionPolicy Bypass -File "$ROOT/scripts/start-li-world-studio.ps1" -Build -Profile "$PROFILE" || true
  fi
fi

HOST_ARGS=(--width "$WIDTH" --height "$HEIGHT")
if [[ "$SCREENSHOT_ONLY" == "1" ]]; then
  HOST_ARGS+=(--screenshot "$PPM")
else
  HOST_ARGS+=(--persist)
  export STUDIO_SHELL_PERSIST=1
fi

echo "start-li-world-studio-macos: profile=$PROFILE backend=metal_wgpu_surface"
"$HOST" "${HOST_ARGS[@]}"

if [[ "$SCREENSHOT_ONLY" == "1" && -f "$PPM" ]]; then
  if [[ -x "$ROOT/scripts/studio-ppm-to-png.py" ]] || command -v python3 >/dev/null 2>&1; then
    python3 "$ROOT/scripts/studio-ppm-to-png.py" "$OUT" "$OUT" 2>/dev/null || true
  fi
  echo "start-li-world-studio-macos: screenshot $PPM"
fi
