#!/usr/bin/env bash
# Build macOS Mach-O SDL present host (wsg-w5-macos-wgpu, PH-HW WP3).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NATIVE="$ROOT/deploy/studio-demo/native"
SRC="$NATIVE/studio_shell_present_host.c"
OUT="$NATIVE/studio_shell_present_host"
PROBE_SRC="$NATIVE/lig_macos_wgpu_surface_probe.c"
PROBE_OUT="$NATIVE/lig_macos_wgpu_surface_probe"
RT="$ROOT/../lic/runtime"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "build-studio-shell-present-host-macos: skip (not Darwin)" >&2
  exit 0
fi

if [[ ! -f "$SRC" ]]; then
  echo "build-studio-shell-present-host-macos: missing $SRC" >&2
  exit 1
fi

build_one() {
  local src="$1"
  local out="$2"
  shift 2
  if [[ -x "$out" && "$src" -ot "$out" ]]; then
    echo "build-studio-shell-present-host-macos: up to date $out"
    return 0
  fi
  if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists sdl2 2>/dev/null; then
    # shellcheck disable=SC2046
    clang -std=c11 -Wall -Wextra -O2 "$src" -o "$out" $(pkg-config --cflags --libs sdl2) "$@"
  elif command -v sdl2-config >/dev/null 2>&1; then
    # shellcheck disable=SC2046
    clang -std=c11 -Wall -Wextra -O2 "$src" -o "$out" $(sdl2-config --cflags --libs) "$@"
  else
    echo "build-studio-shell-present-host-macos: install SDL2 (brew install sdl2)" >&2
    exit 4
  fi
  echo "build-studio-shell-present-host-macos: built $out"
}

build_one "$SRC" "$OUT"

if [[ -f "$PROBE_SRC" && -f "$RT/li_rt.h" && -f "$RT/li_rt.c" ]]; then
  if [[ ! -x "$PROBE_OUT" || "$PROBE_SRC" -nt "$PROBE_OUT" || "$RT/li_rt.c" -nt "$PROBE_OUT" ]]; then
    clang -std=c11 -Wall -Wextra -O2 -I"$RT" "$PROBE_SRC" "$RT/li_rt.c" -o "$PROBE_OUT"
    echo "build-studio-shell-present-host-macos: built $PROBE_OUT"
  fi
fi
