#!/usr/bin/env bash
# Progress gate: Li World Studio runnable slice (Windows/WSL friendly).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"

fail() { echo "FAIL: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }

LIC="${LIC:-}"
if ! LIC="$(resolve_lic 2>/dev/null)"; then
  LIC=""
fi

[[ -f "$ROOT/src/main.li" ]] || fail "li-studio main.li missing"
grep -q 'li-sim-sensors' "$ROOT/li.toml" || fail "li-sim-sensors not in li.toml dependencies"
[[ -f "$ROOT/installer/LiWorldStudio.iss" ]] || fail "installer/LiWorldStudio.iss missing"
[[ -f "$ROOT/scripts/start-li-world-studio.ps1" ]] || fail "scripts/start-li-world-studio.ps1 missing"

wsl_lic_root_path() {
  local p="$LIC_ROOT"
  p="${p//\\//}"
  if [[ "$p" =~ ^/([a-zA-Z])/(.*)$ ]]; then
    echo "/mnt/${BASH_REMATCH[1],,}/${BASH_REMATCH[2]}"
    return
  fi
  if [[ "$p" =~ ^([A-Za-z]):/(.*)$ ]]; then
    echo "/mnt/${BASH_REMATCH[1],,}/${BASH_REMATCH[2]}"
    return
  fi
  echo "$p"
}

wsl_studio_root_path() {
  local p="$ROOT"
  p="${p//\\//}"
  if [[ "$p" =~ ^/([a-zA-Z])/(.*)$ ]]; then
    echo "/mnt/${BASH_REMATCH[1],,}/${BASH_REMATCH[2]}"
    return
  fi
  if [[ "$p" =~ ^([A-Za-z]):/(.*)$ ]]; then
    echo "/mnt/${BASH_REMATCH[1],,}/${BASH_REMATCH[2]}"
    return
  fi
  echo "$p"
}

lic_check_smoke() {
  local smoke="$1"
  local path="$ROOT/li-tests/smoke/$smoke"
  [[ -f "$path" ]] || fail "missing $smoke"
  if [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]] && command -v wsl >/dev/null 2>&1; then
    local wsl_lic wsl_studio
    wsl_lic="$(wsl_lic_root_path)"
    wsl_studio="$(wsl_studio_root_path)"
    wsl -e bash -lc "cd '$wsl_studio' && '$wsl_lic/build-wsl/compiler/lic/lic' check --no-cache 'li-tests/smoke/$smoke'" \
      || fail "lic check $smoke (wsl)"
  elif [[ -n "$LIC" && -x "$LIC" ]]; then
    "$LIC" check "$path" || fail "lic check $smoke"
  else
    warn "lic not runnable — skipping lic check smokes"
    return 0
  fi
}

if [[ -n "$LIC" || -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; then
  lic_check_smoke studio_shell_demo.li
  lic_check_smoke studio_sim_step_by_profile.li
else
  warn "lic not built — skipping lic check smokes"
fi

echo "OK world-studio-runnable-gate"