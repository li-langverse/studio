#!/usr/bin/env bash
# Launch Li World Studio on Linux via AppDir or AppImage (wsg-w5-linux-appimage).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"

PROFILE="${STUDIO_DEMO_PROFILE:-game}"
WIDTH="${STUDIO_SHELL_WIDTH:-1280}"
HEIGHT="${STUDIO_SHELL_HEIGHT:-720}"
BUILD="${STUDIO_LINUX_BUILD:-0}"
SCREENSHOT_ONLY="${STUDIO_LINUX_SCREENSHOT_ONLY:-0}"

APPDIR="$ROOT/installer/out/LiWorldStudio.AppDir"
APPIMAGE="$ROOT/installer/out/LiWorldStudio-x86_64.AppImage"
HOST="$ROOT/deploy/studio-demo/native/studio_shell_present_host"
OUT="$ROOT/installer/out"
PPM="$OUT/frame-000.ppm"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "start-li-world-studio-linux: requires Linux" >&2
  exit 2
fi

chmod +x "$ROOT/scripts/build-studio-linux-appimage.sh" 2>/dev/null || true
"$ROOT/scripts/build-studio-linux-appimage.sh"

LAUNCHER=""
if [[ -f "$APPIMAGE" && -x "$APPIMAGE" ]]; then
  LAUNCHER="$APPIMAGE"
elif [[ -x "$APPDIR/AppRun" ]]; then
  LAUNCHER="$APPDIR/AppRun"
elif [[ -x "$HOST" ]]; then
  LAUNCHER="$HOST"
else
  echo "start-li-world-studio-linux: no launcher (run build-studio-linux-appimage.sh)" >&2
  exit 3
fi

mkdir -p "$OUT"
export STUDIO_DEMO_PROFILE="$PROFILE"
export LIG_HOST_PRESENT=1
export LIG_WGPU_SWAPCHAIN=1
export LIG_GPU_RUNNER=1
export STUDIO_SHELL_PRESENT_HOST_BIN="$HOST"

if [[ "$BUILD" == "1" && -x "$ROOT/scripts/start-li-world-studio.ps1" ]]; then
  powershell -NoProfile -ExecutionPolicy Bypass -File "$ROOT/scripts/start-li-world-studio.ps1" -Build -Profile "$PROFILE" 2>/dev/null || true
fi

HOST_ARGS=(--width "$WIDTH" --height "$HEIGHT")
if [[ "$SCREENSHOT_ONLY" == "1" ]]; then
  HOST_ARGS+=(--screenshot "$PPM")
else
  HOST_ARGS+=(--persist)
  export STUDIO_SHELL_PERSIST=1
fi

echo "start-li-world-studio-linux: profile=$PROFILE launcher=$(basename "$LAUNCHER") backend=linux_appimage_sdl_wgpu"
"$LAUNCHER" "${HOST_ARGS[@]}"

if [[ "$SCREENSHOT_ONLY" == "1" && -f "$PPM" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 "$ROOT/scripts/studio-ppm-to-png.py" "$OUT" "$OUT" 2>/dev/null || true
  fi
  echo "start-li-world-studio-linux: screenshot $PPM"
fi
