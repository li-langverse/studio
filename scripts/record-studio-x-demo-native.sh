#!/usr/bin/env bash
# Optional native viewport capture — requires DISPLAY (macOS window server or Xvfb).
# Full li-studio chrome is not capturable here until PH-GD-5 host window ships.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIC_ROOT="${LIC_ROOT:-$ROOT/../lic}"
CACHE="${STUDIO_DEMO_CACHE:-$ROOT/.demo-cache}"
NATIVE="$CACHE/deploy/studio-demo/native"

if [[ -z "${DISPLAY:-}" ]]; then
  echo "record-studio-x-demo-native: DISPLAY unset — native capture blocked (see docs/demo/RECORDING.md)" >&2
  exit 0
fi

if [[ ! -f "$NATIVE/capture.sh" ]]; then
  echo "record-studio-x-demo-native: extract mocks first (STUDIO_DEMO_REFRESH=1 ./scripts/record-studio-x-demo.sh)" >&2
  exit 1
fi

export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-/opt/homebrew/lib/pkgconfig}"
STUDIO_VIEWPORT_CAPTURE_OUT="${STUDIO_VIEWPORT_CAPTURE_OUT:-$NATIVE/out}"
mkdir -p "$STUDIO_VIEWPORT_CAPTURE_OUT"
echo "record-studio-x-demo-native: SDL grid stub → $STUDIO_VIEWPORT_CAPTURE_OUT"
bash "$NATIVE/capture.sh"
