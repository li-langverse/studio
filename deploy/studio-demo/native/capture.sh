#!/usr/bin/env bash
# Build SDL viewport stub and capture PPM frames (Xvfb when DISPLAY unset).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/studio_viewport_capture.c"
BIN="${STUDIO_VIEWPORT_CAPTURE_BIN:-$ROOT/studio_viewport_capture}"
OUT="${STUDIO_VIEWPORT_CAPTURE_OUT:-$ROOT/out}"
FRAMES="${STUDIO_VIEWPORT_CAPTURE_FRAMES:-3}"
WIDTH="${STUDIO_VIEWPORT_CAPTURE_WIDTH:-1280}"
HEIGHT="${STUDIO_VIEWPORT_CAPTURE_HEIGHT:-720}"

mkdir -p "$OUT"

need_build=0
if [[ ! -x "$BIN" ]]; then
  need_build=1
elif [[ "$SRC" -nt "$BIN" ]]; then
  need_build=1
fi
if [[ "$need_build" == 1 ]]; then
  if ! command -v pkg-config >/dev/null 2>&1; then
    echo "capture-native: pkg-config missing" >&2
    exit 4
  fi
  if ! pkg-config --exists sdl2 2>/dev/null; then
    echo "capture-native: libsdl2-dev not installed" >&2
    exit 4
  fi
  SDL_FLAGS="$(pkg-config --cflags --libs sdl2)"
  # shellcheck disable=SC2086
  gcc -std=c11 -Wall -Wextra -O2 "$SRC" -o "$BIN" $SDL_FLAGS
fi

run_capture() {
  "$BIN" --out "$OUT" --width "$WIDTH" --height "$HEIGHT" --frames "$FRAMES"
}

if [[ -n "${DISPLAY:-}" ]]; then
  run_capture
elif command -v xvfb-run >/dev/null 2>&1; then
  xvfb-run -a -s "-screen 0 ${WIDTH}x${HEIGHT}x24" \
    "$BIN" --out "$OUT" --width "$WIDTH" --height "$HEIGHT" --frames "$FRAMES"
elif command -v Xvfb >/dev/null 2>&1; then
  DISP=":199"
  Xvfb "$DISP" -screen 0 "${WIDTH}x${HEIGHT}x24" >/dev/null 2>&1 &
  XPID=$!
  sleep 0.5
  DISPLAY="$DISP" run_capture
  kill "$XPID" 2>/dev/null || true
else
  echo "capture-native: no DISPLAY and no Xvfb" >&2
  exit 5
fi
