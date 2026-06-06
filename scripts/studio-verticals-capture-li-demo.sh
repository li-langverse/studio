#!/usr/bin/env bash
# WP-UX-14b Step 1: capture via studio_vertical_capture_ppm_auto (Li API + runtime paint).
# Optional: LIG_WGPU_READBACK=1 LIG_HOST_PRESENT=1 for readback-gated demo frame (PPM still paint mirror).
# Falls back to C paint_blit host when capture_vertical binary is missing.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CAP_BIN="${STUDIO_CAPTURE_VERTICAL_BIN:-$ROOT/build/studio-capture-vertical}"
PNG_DIR="${STUDIO_VERTICALS_NATIVE_PNG_DIR:-$ROOT/docs/demo/media/native-verticals/png}"
PPM_PATH="${STUDIO_CAPTURE_PPM:-/tmp/studio-vertical-capture.ppm}"
VERTICALS=(game sim_rl sim_automotive sim_robotics sim_additive sim_scientific sim_drug_design)

if ! command -v lic >/dev/null 2>&1; then
  echo "studio-verticals-capture-li-demo: lic not on PATH; fallback to C capture" >&2
  exec "$ROOT/scripts/studio-verticals-capture-native.sh"
fi

if [[ ! -x "$CAP_BIN" ]]; then
  lic build --allow-open-vc --no-lean-verify src/capture_vertical.li -o "$CAP_BIN"
fi

mkdir -p "$PNG_DIR"
native_ok=0
for slug in "${VERTICALS[@]}"; do
  tmp="$(mktemp -d)"
  export STUDIO_DEMO_PROFILE="$slug"
  export STUDIO_CAPTURE_PPM="$PPM_PATH"
  if ! "$CAP_BIN"; then
    rm -rf "$tmp"
    echo "studio-verticals-capture-li-demo: capture_vertical failed for $slug" >&2
    continue
  fi
  if [[ ! -f "$PPM_PATH" ]]; then
    rm -rf "$tmp"
    echo "studio-verticals-capture-li-demo: missing $PPM_PATH for $slug" >&2
    continue
  fi
  cp "$PPM_PATH" "$tmp/frame-000.ppm"
  if ! python3 "$ROOT/scripts/studio-ppm-to-png.py" "$tmp" "$tmp" >/dev/null 2>&1; then
    rm -rf "$tmp"
    echo "studio-verticals-capture-li-demo: ppm→png failed for $slug" >&2
    continue
  fi
  if [[ -f "$tmp/frame-000.png" ]]; then
    cp "$tmp/frame-000.png" "$PNG_DIR/${slug}.png"
    native_ok=$((native_ok + 1))
    echo "studio-verticals-capture-li-demo: $slug native_pixels=1 capture_mode=li_ppm"
  fi
  rm -rf "$tmp"
done

if [[ "$native_ok" -lt 2 ]]; then
  echo "studio-verticals-capture-li-demo: insufficient Li captures ($native_ok); fallback C host" >&2
  exec "$ROOT/scripts/studio-verticals-capture-native.sh"
fi
echo "studio-verticals-capture-li-demo: captured $native_ok verticals via Li PPM path"
