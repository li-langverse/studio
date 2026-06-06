#!/usr/bin/env bash
# Shared packaging helpers for Li World Studio installers (AppImage, Inno, dmg).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
export ROOT="$STUDIO_ROOT"

demo_binary() {
  for c in "$STUDIO_ROOT/build/li-studio-demo" "$STUDIO_ROOT/build/li-studio-demo.exe"; do
    if [[ -f "$c" ]]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

ensure_demo_binary() {
  local lic main out
  main="$STUDIO_ROOT/src/main.li"
  out="$STUDIO_ROOT/build/li-studio-demo"
  [[ -f "$main" ]] || { echo "missing $main" >&2; return 1; }
  if demo_binary >/dev/null 2>&1; then
    demo_binary
    return 0
  fi
  lic="$(resolve_lic)" || { echo "lic not found under $LIC_ROOT" >&2; return 1; }
  mkdir -p "$STUDIO_ROOT/build"
  "$lic" build --allow-open-vc --no-lean-verify "$main" -o "$out"
  demo_binary
}

present_host_native_dir() {
  echo "$STUDIO_ROOT/deploy/studio-demo/native"
}
