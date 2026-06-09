#!/usr/bin/env bash
# Completion gate: Li World Studio runnable + installer (Windows/WSL friendly).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"

fail() { echo "$*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }

LIC="${LIC:-}"
if ! LIC="$(resolve_lic 2>/dev/null)"; then
  fail "lic binary missing under $LIC_ROOT"
fi
export LIC

[[ -f "$ROOT/build/li-studio-demo" || -f "$ROOT/build/li-studio-demo.exe" ]] \
  || fail "li-studio-demo missing (build with start-li-world-studio.ps1 -Build)"

wsl_studio_root_path() {
  local p="$ROOT"
  p="${p//\\//}"
  if [[ "$p" =~ ^([A-Za-z]):/(.*)$ ]]; then
    echo "/mnt/${BASH_REMATCH[1],,}/${BASH_REMATCH[2]}"
    return
  fi
  echo "$p"
}

lic_check_smoke() {
  local smoke="$1"
  [[ -f "$ROOT/li-tests/smoke/$smoke" ]] || fail "missing smoke $smoke"
  if [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]] && command -v wsl >/dev/null 2>&1; then
    local wsl_studio wsl_lic
    wsl_studio="$(wsl_studio_root_path)"
    wsl_lic="${LIC_ROOT//\\//}"
    if [[ "$wsl_lic" =~ ^([A-Za-z]):/(.*)$ ]]; then wsl_lic="/mnt/${BASH_REMATCH[1],,}/${BASH_REMATCH[2]}"; fi
    wsl -e bash -lc "cd '$wsl_studio' && '$wsl_lic/build-wsl/compiler/lic/lic' check --no-cache 'li-tests/smoke/$smoke'" \
      || fail "lic check $smoke (wsl)"
  else
    "$LIC" check "$ROOT/li-tests/smoke/$smoke" || fail "lic check $smoke"
  fi
}

lic_check_smoke studio_shell_demo.li
lic_check_smoke studio_sim_step_by_profile.li

if command -v iscc >/dev/null 2>&1; then
  iscc /Qp "$ROOT/installer/LiWorldStudio.iss" || fail "iscc compile failed"
else
  warn "Inno Setup (iscc) not on PATH — skip installer compile"
fi

echo "OK world-studio-runnable-completion-gate"