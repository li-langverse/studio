#!/usr/bin/env bash
# Plan-loop wsm-w6-vertical-dod — composable DoD for all 7 runtime profiles.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/li-ui.sh
source "$ROOT/scripts/lib/li-ui.sh"
export LI_REPO_ROOT="$ROOT"

fail() { li_gate_fail "$*"; exit 1; }

li_phase "vertical DoD smoke"
[[ -f "$ROOT/li-tests/smoke/studio_vertical_dod.li" ]] || fail "missing studio_vertical_dod.li"

LIC="${LIC:-}"
if [[ -x "$LIC_ROOT/build/compiler/lic/lic" ]]; then
  LIC="$LIC_ROOT/build/compiler/lic/lic"
elif [[ -x "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; then
  LIC="$LIC_ROOT/build-wsl/compiler/lic/lic"
elif [[ -x "$LIC_ROOT/scripts/resolve-lic.sh" ]]; then
  LIC="$("$LIC_ROOT/scripts/resolve-lic.sh" 2>/dev/null)" || true
fi

if [[ -n "$LIC" && -x "$LIC" ]]; then
  li_phase "lic check vertical DoD"
  (cd "$ROOT" && "$LIC" check "li-tests/smoke/studio_vertical_dod.li") \
    || fail "lic check studio_vertical_dod.li"
else
  li_warn "lic not built — smoke path verified only"
fi

li_ok "studio-vertical-dod-gate"
