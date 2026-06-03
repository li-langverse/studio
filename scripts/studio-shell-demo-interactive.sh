#!/usr/bin/env bash
# Interactive studio shell demo — SDL input poll + li-studio-demo frame ticks (CI-safe mock fallback).
#
# Honesty: this drives the real Li present-loop binary (compose/paint IR). Viewport pixels are
# simulate (headless) unless LIG_HOST_PRESENT=1, which uses paint_blit / studio_shell_present_host
# (SDL stub window) — not wgpu-rs swapchain readback.
#
# Usage (lic repo root):
#   ./scripts/studio-shell-demo-interactive.sh
#   LIG_HOST_PRESENT=1 STUDIO_INTERACTIVE_TICK_MS=33 ./scripts/studio-shell-demo-interactive.sh
#   STUDIO_SHELL_DEMO_BIN=build/li-studio-demo ./scripts/studio-shell-demo-interactive.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIC="${LIC:-$("$LIC_ROOT/scripts/resolve-lic.sh")}"
BIN="${STUDIO_SHELL_DEMO_BIN:-$ROOT/build/li-studio-demo}"
TICK_MS="${STUDIO_INTERACTIVE_TICK_MS:-16}"
MAX_TICKS="${STUDIO_INTERACTIVE_MAX_TICKS:-3600}"
export STUDIO_DEMO_PROFILE="${STUDIO_DEMO_PROFILE:-game}"
# One composed frame per binary invocation; pattern 0→1→2 via STUDIO_DEMO_LOOP_TICK.
export STUDIO_DEMO_FRAMES="${STUDIO_DEMO_FRAMES:-1}"
export LIG_HOST_PRESENT="${LIG_HOST_PRESENT:-0}"

if [[ ! -x "$BIN" ]]; then
  mkdir -p "$(dirname "$BIN")"
  "$LIC" build --allow-open-vc --no-lean-verify \
    "$ROOT/src/main.li" -o "$BIN"
fi

if [[ "$LIG_HOST_PRESENT" == "1" ]]; then
  export STUDIO_SHELL_PRESENT_HOST_BIN="${STUDIO_SHELL_PRESENT_HOST_BIN:-$ROOT/deploy/studio-demo/native/studio_shell_present_host}"
fi

echo "studio-shell-demo-interactive: bin=$BIN profile=$STUDIO_DEMO_PROFILE frames=$STUDIO_DEMO_FRAMES lig_host_present=$LIG_HOST_PRESENT tick_ms=$TICK_MS" >&2

tick=0
while [[ "$tick" -lt "$MAX_TICKS" ]]; do
  export STUDIO_DEMO_LOOP_TICK="$tick"
  if [[ "${STUDIO_SHELL_FORCE_MOCK:-0}" == "1" ]]; then
    STUDIO_SHELL_FORCE_MOCK=1 \
      STUDIO_SHELL_INPUT_MOCK="${STUDIO_SHELL_INPUT_MOCK:-cmd_k,digit=3}" \
      bash "$ROOT/scripts/studio-shell-sdl-tick.sh" >/dev/null
  else
    if ! bash "$ROOT/scripts/studio-shell-sdl-tick.sh" >/dev/null 2>&1; then
      STUDIO_SHELL_FORCE_MOCK=1 \
        STUDIO_SHELL_INPUT_MOCK="${STUDIO_SHELL_INPUT_MOCK:-cmd_k,digit=3}" \
        bash "$ROOT/scripts/studio-shell-sdl-tick.sh" >/dev/null
    fi
  fi

  if ! "$BIN"; then
    echo "studio-shell-demo-interactive: li-studio-demo exited non-zero at tick=$tick" >&2
    exit 4
  fi

  if [[ "$LIG_HOST_PRESENT" == "1" ]]; then
    bash "$ROOT/scripts/studio-shell-present-tick.sh" >/dev/null 2>&1 || true
  fi

  tick=$((tick + 1))
  sleep "$(awk "BEGIN { printf \"%.3f\", $TICK_MS / 1000.0 }")"
done

echo "studio-shell-demo-interactive: reached max ticks ($MAX_TICKS)" >&2
