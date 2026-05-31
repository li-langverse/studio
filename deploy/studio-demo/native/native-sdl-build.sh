#!/usr/bin/env bash
# Build a native stub binary (SDL when needed; CPU-only sources need no SDL).
set -euo pipefail
SRC="${1:?source.c}"
OUT="${2:?output binary}"
DIR="$(cd "$(dirname "$SRC")" && pwd)"
BASE="$(basename "$SRC")"
needs_sdl=0
if grep -q 'SDL.h' "$SRC" 2>/dev/null; then
  needs_sdl=1
fi
extra=()
if [[ "$BASE" == "studio_shell_present_host.c" ]] && [[ -f "$DIR/studio_shell_paint_fb.c" ]]; then
  extra+=("$DIR/studio_shell_paint_fb.c")
fi
if [[ -x "$OUT" ]]; then
  stale=0
  if [[ "$SRC" -nt "$OUT" ]]; then stale=1; fi
  for f in "${extra[@]}"; do
    if [[ "$f" -nt "$OUT" ]]; then stale=1; fi
  done
  if [[ "$stale" -eq 0 ]]; then
    exit 0
  fi
  rm -f "$OUT"
fi
if [[ "$needs_sdl" -eq 0 ]]; then
  cc -std=c11 -Wall -Wextra -O2 "${extra[@]}" "$SRC" -o "$OUT"
  exit 0
fi
if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists sdl2 2>/dev/null; then
  # shellcheck disable=SC2046
  gcc -std=c11 -Wall -Wextra -O2 "${extra[@]}" "$SRC" -o "$OUT" $(pkg-config --cflags --libs sdl2)
  exit 0
fi
if command -v sdl2-config >/dev/null 2>&1; then
  # shellcheck disable=SC2046
  cc -std=c11 -Wall -Wextra -O2 "${extra[@]}" "$SRC" -o "$OUT" $(sdl2-config --cflags --libs)
  exit 0
fi
echo "native-sdl-build: install SDL2 (libsdl2-dev or brew install sdl2)" >&2
exit 4
