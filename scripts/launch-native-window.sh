#!/usr/bin/env bash
# Launch Li World Studio native SDL window (host I/O only).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NATIVE="$ROOT/deploy/studio-demo/native"
BIN="$NATIVE/studio_shell_present_host"
OUT="$NATIVE/out"
PPM="$OUT/frame-000.ppm"
PNG="$ROOT/docs/demo/media/native-verticals/png/launch-native-window.png"

PROFILE_ID="${STUDIO_LAUNCH_PROFILE_ID:-1}"
WIDTH="${STUDIO_LAUNCH_WIDTH:-1280}"
HEIGHT="${STUDIO_LAUNCH_HEIGHT:-720}"
HEADLESS="${STUDIO_LAUNCH_HEADLESS:-0}"

mkdir -p "$OUT" "$(dirname "$PNG")"

cc -std=c11 -Wall -Wextra -O2 \
  "$NATIVE/studio_shell_present_host.c" \
  -o "$BIN" $(pkg-config --cflags --libs sdl2)

args=(--width "$WIDTH" --height "$HEIGHT" --profile-id "$PROFILE_ID" --screenshot "$PPM")
if [[ "$HEADLESS" != "1" ]]; then
  args+=(--persist)
fi

echo "launch-native-window: $BIN ${args[*]}"
export STUDIO_SHELL_RGB_PPM="${STUDIO_SHELL_RGB_PPM:-$PPM}"
"$BIN" "${args[@]}"

if [[ -f "$PPM" ]]; then
  python3 "$ROOT/scripts/studio-ppm-to-png.py" "$OUT" "$OUT" >/dev/null 2>&1 || true
  if [[ -f "$OUT/frame-000.png" ]]; then
    cp "$OUT/frame-000.png" "$PNG"
    echo "Screenshot: $PNG"
  else
    echo "PPM frame: $PPM"
  fi
fi

cat <<EOF

REAL because:
  - SDL window on desktop, not 01-studio-workspace.html
  - Pixels presented from Li raster PPM ($PPM) when available
  - backend=sdl_li_blit when Li pixels present; io-only fallback otherwise

lic runtime:
  export LIG_HOST_PRESENT=1
  export STUDIO_SHELL_PRESENT_HOST_BIN=$BIN
  export STUDIO_SHELL_RGB_PPM=$PPM
EOF
