#!/usr/bin/env bash
# Build studio_verticals_present_host (paint_blit styled chrome capture) for gate verification.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NATIVE="$ROOT/deploy/studio-demo/native"
BIN="$NATIVE/studio_verticals_present_host"

if [[ -f "$BIN" ]] && [[ "${STUDIO_VERTICALS_HOST_FORCE_REBUILD:-0}" != "1" ]]; then
  exit 0
fi

if [[ ! -f "$NATIVE/studio_shell_paint_fb.c" || ! -f "$NATIVE/studio_verticals_present_host.c" ]]; then
  echo "build-studio-verticals-host: missing native sources under $NATIVE" >&2
  exit 1
fi

build_with_cc() {
  local cc_bin="$1"
  rm -f "$BIN" 2>/dev/null || true
  "$cc_bin" -std=c11 -Wall -Wextra -O2 \
    "$NATIVE/studio_shell_paint_fb.c" \
    "$NATIVE/studio_verticals_present_host.c" \
    -o "$BIN"
}

if command -v cc >/dev/null 2>&1; then
  build_with_cc cc
  exit 0
fi

if command -v wsl >/dev/null 2>&1; then
  wsl_root="$(wsl wslpath -u "$ROOT" 2>/dev/null | tr -d '\r\n')"
  wsl -e bash -lc "cd '$wsl_root/deploy/studio-demo/native' && cc -std=c11 -Wall -Wextra -O2 studio_shell_paint_fb.c studio_verticals_present_host.c -o studio_verticals_present_host"
  exit 0
fi

echo "build-studio-verticals-host: no cc or wsl — cannot build capture host" >&2
exit 1
