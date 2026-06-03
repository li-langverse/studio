#!/usr/bin/env bash
# Studio GPU decorator sprint completion gate (native or WSL build-wsl).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

run_gate() {
  sed -i 's/\r$//' li-tests/run_all.sh scripts/lib/li-ui.sh 2>/dev/null || true
  bash li-tests/run_all.sh decorators decorator_exploits
  echo "studio-gpu-decorator: completion gate OK"
}

if [[ -x "$LIC_ROOT/build/compiler/lic/lic" ]]; then
  run_gate
  exit 0
fi
if [[ -x "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; then
  run_gate
  exit 0
fi
if command -v wsl >/dev/null 2>&1 && ! grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
  WSL_ROOT="/mnt/c/Users/Julian/Documents/Programming/li/lic"
  wsl bash -lc "test -x '$WSL_ROOT/build-wsl/compiler/lic/lic' || { echo 'WSL build-wsl missing — run cmake -B build-wsl in WSL'; exit 1; }; cd '$WSL_ROOT' && bash scripts/studio-gpu-decorator-gate.sh"
  exit $?
fi
echo "build lic first: ./scripts/build.sh (or WSL build-wsl)"
exit 1
