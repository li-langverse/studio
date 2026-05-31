#!/usr/bin/env bash
# Run world-studio-plan-lic-smokes inside WSL (Windows Git Bash / plan gates).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if ! command -v wsl.exe >/dev/null 2>&1; then
  echo "world-studio-plan-lic-smokes-wsl: wsl.exe not found" >&2
  exit 1
fi
wsl_root="$(wsl.exe wslpath -u "$ROOT" 2>/dev/null | tr -d '\r\n')"
[[ -n "$wsl_root" ]] || {
  echo "world-studio-plan-lic-smokes-wsl: wslpath failed for repo root" >&2
  exit 1
}
MSYS2_ARG_CONV_EXCL='*' MSYS_NO_PATHCONV=1 wsl.exe bash -lc "cd '$wsl_root' && LIC=./build-wsl/compiler/lic/lic bash ./scripts/world-studio-plan-lic-smokes.sh"
