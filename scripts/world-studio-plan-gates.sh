#!/usr/bin/env bash
# Gates for World Studio master plan loop Â native li-studio smokes + plan docs.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/li-ui.sh
source "$ROOT/scripts/lib/li-ui.sh"
li_detect_compilers 2>/dev/null || true
export LI_REPO_ROOT="$ROOT"

fail() { li_gate_fail "$*"; exit 1; }

LIC="${LIC:-}"
if [[ -x "$LIC_ROOT/build/compiler/lic/lic" ]]; then
  LIC="$LIC_ROOT/build/compiler/lic/lic"
elif [[ -x "$LIC_ROOT/build/compiler/lic/lic.exe" ]]; then
  LIC="$LIC_ROOT/build/compiler/lic/lic.exe"
elif [[ "$(uname -s)" == "Linux" && -x "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; then
  LIC="$LIC_ROOT/build-wsl/compiler/lic/lic"
elif [[ -x "$LIC_ROOT/scripts/resolve-lic.sh" ]]; then
  LIC="$("$LIC_ROOT/scripts/resolve-lic.sh" 2>/dev/null)" || true
fi

li_phase "plan documents"
[[ -f "$ROOT/docs/game-dev/WORLD-STUDIO-MASTER-PLAN.md" ]] || fail "WORLD-STUDIO-MASTER-PLAN.md"
[[ -f "$ROOT/docs/superpowers/plans/2026-05-29-world-studio-master-plan-loop.md" ]] || fail "world-studio plan loop yaml"
[[ -f "$ROOT/.cursor/rules/li-studio-demo-native-only.mdc" ]] || fail "li-studio-demo-native-only rule"
[[ -f "$ROOT/docs/game-dev/studio-mcp-tools.md" ]] || fail "studio-mcp-tools.md"

li_phase "loop scripts"
[[ -x "$ROOT/scripts/world-studio-plan-loop.py" ]] || chmod +x "$ROOT/scripts/world-studio-plan-loop.py"
[[ -f "$ROOT/scripts/world-studio-plan-commit-push.sh" ]] || fail "world-studio-plan-commit-push.sh"

li_phase "design tokens"
[[ -f "$ROOT/docs/design/studio-design-tokens.toml" ]] || fail "studio-design-tokens.toml"

run_lic_smokes() {
  li_phase "lic check smokes"
  LIC="$1" bash "$ROOT/scripts/world-studio-plan-lic-smokes.sh"
}

wsl_build_wsl_lic_ready() {
  command -v wsl.exe >/dev/null 2>&1 || return 1
  local wsl_root
  wsl_root="$(wsl.exe wslpath -u "$ROOT" 2>/dev/null | tr -d '\r\n')"
  [[ -n "$wsl_root" ]] || return 1
  wsl.exe bash -lc "test -x '$wsl_root/build-wsl/compiler/lic/lic'" 2>/dev/null
}

try_wsl_lic_smokes() {
  [[ "${WORLD_STUDIO_GATES_WSL:-auto}" == "0" ]] && return 1
  wsl_build_wsl_lic_ready || return 1
  [[ -f "$ROOT/scripts/world-studio-plan-lic-smokes-wsl.sh" ]] || return 1
  li_phase "wsl lic check smokes"
  local attempt
  for attempt in 1 2 3; do
    if bash "$ROOT/scripts/world-studio-plan-lic-smokes-wsl.sh"; then
      return 0
    fi
    [[ "$attempt" -lt 3 ]] && sleep 2
  done
  return 1
}
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" == "1" ]]; then
  li_warn "skip lic check smokes (WORLD_STUDIO_GATES_SKIP_LIC=1)"
elif [[ -n "$LIC" && -x "$LIC" ]]; then
  run_lic_smokes "$LIC"
elif try_wsl_lic_smokes; then
  li_ok "wsl lic smokes passed"
else
  li_warn "lic not built - set WORLD_STUDIO_GATES_SKIP_LIC=1, build lic, or enable WSL"
fi

if [[ -f "$ROOT/scripts/bench-studio-viewport-perf.sh" ]]; then
  li_phase "viewport bench (soft)"
  "$ROOT/scripts/bench-studio-viewport-perf.sh" || li_warn "bench-studio-viewport-perf soft-fail"
fi

if [[ -x "$ROOT/scripts/studio-c-host-retirement-gate.sh" ]]; then
  li_phase "c-host retirement (WP-UX-14b)"
  "$ROOT/scripts/studio-c-host-retirement-gate.sh" || li_warn "studio-c-host-retirement-gate soft-fail"
fi

if [[ -x "$ROOT/scripts/studio-mcp-li-engine-smoke.sh" ]]; then
  li_phase "mcp li-engine stdio (WP-AG-03)"
  "$ROOT/scripts/studio-mcp-li-engine-smoke.sh" || li_warn "studio-mcp-li-engine-smoke soft-fail"
fi

if [[ -x "$ROOT/scripts/studio-patch-eval-gate.sh" ]]; then
  li_phase "patch eval harness (WP-AG-06)"
  "$ROOT/scripts/studio-patch-eval-gate.sh" || fail "studio-patch-eval-gate"
fi

if [[ -x "$ROOT/scripts/studio-vertical-dod-gate.sh" ]]; then
  li_phase "vertical DoD composable (wsm-w6)"
  "$ROOT/scripts/studio-vertical-dod-gate.sh" || fail "studio-vertical-dod-gate"
fi

li_phase "iteration assessment"
assess="$ROOT/data/world-studio-plan-loop/latest-iteration-assessment.json"
if [[ -f "$assess" ]]; then
  (cd "$ROOT" && python3 -c "
import json, sys
from pathlib import Path
p = Path('data/world-studio-plan-loop/latest-iteration-assessment.json')
d = json.loads(p.read_text(encoding='utf-8'))
if not d.get('native_only', True):
    print('assessment: native_only must be true', file=sys.stderr)
    sys.exit(1)
") || fail "latest-iteration-assessment.json native_only=false"
else
  li_warn "no latest-iteration-assessment.json yet (agent should write after iteration)"
fi

li_ok "world-studio plan gates"
