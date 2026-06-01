#!/usr/bin/env bash
# li-studio-demo present loop — host input mock + optional LIG_HOST_PRESENT tick (CI-safe).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$ROOT"
SMOKE="$PKG/li-tests/smoke/studio_shell_demo_present_loop.li"
LIC="${LIC:-$("$LIC_ROOT/scripts/resolve-lic.sh")}"

export STUDIO_DEMO_PROFILE="${STUDIO_DEMO_PROFILE:-game}"
export STUDIO_DEMO_FRAMES="${STUDIO_DEMO_FRAMES:-3}"
export LIG_HOST_PRESENT="${LIG_HOST_PRESENT:-0}"

if [[ "${STUDIO_SHELL_DEMO_PREP_HOST:-1}" == "1" ]]; then
  STUDIO_SHELL_FORCE_MOCK="${STUDIO_SHELL_FORCE_MOCK:-1}" \
    STUDIO_SHELL_INPUT_MOCK="${STUDIO_SHELL_INPUT_MOCK:-cmd_k,digit=3}" \
    bash "$ROOT/scripts/studio-shell-sdl-tick.sh" >/dev/null
fi

if [[ "$LIG_HOST_PRESENT" == "1" ]]; then
  export STUDIO_SHELL_PRESENT_HOST_BIN="${STUDIO_SHELL_PRESENT_HOST_BIN:-$ROOT/deploy/studio-demo/native/studio_shell_present_host}"
  bash "$ROOT/scripts/studio-shell-present-tick.sh" >/dev/null || true
fi

if [[ "${STUDIO_SHELL_DEMO_LIC_ONLY:-0}" == "1" ]]; then
  exec "$LIC" check "$SMOKE"
fi

"$LIC" check "$SMOKE"
"$LIC" check "$PKG/src/main.li"

if [[ "${STUDIO_SHELL_DEMO_BUILD_RUN:-0}" == "1" ]]; then
  OUT="${STUDIO_SHELL_DEMO_BIN:-$ROOT/build/li-studio-demo}"
  mkdir -p "$(dirname "$OUT")"
  "$LIC" build --allow-open-vc --no-lean-verify "$PKG/src/main.li" -o "$OUT"
  exec "$OUT"
fi
