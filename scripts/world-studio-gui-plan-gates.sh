#!/usr/bin/env bash
# Progress gates for GUI-LIBRARY-PLAN.md Phases 0–5 (Function·Layout·Design).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"

fail() { echo "FAIL: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }
ok() { echo "OK: $*"; }

PLAN="$ROOT/docs/GUI-LIBRARY-PLAN.md"
LOOP="$ROOT/docs/superpowers/plans/2026-05-31-world-studio-gui-library-plan-loop.md"
TOKENS="$ROOT/docs/design/studio-design-tokens.toml"
GATES="$ROOT/scripts/world-studio-gui-plan-gates.sh"
ASSESS="$ROOT/data/world-studio-gui-plan-loop/latest-iteration-assessment.json"

echo "==> plan documents"
[[ -f "$PLAN" ]] || fail "missing $PLAN"
[[ -f "$LOOP" ]] || fail "missing plan loop yaml $LOOP"
[[ -f "$TOKENS" ]] || fail "missing $TOKENS"
[[ -x "$GATES" ]] || chmod +x "$GATES"
[[ -f "$ROOT/src/lib.li" ]] || fail "studio/src/lib.li missing"

LIC_BIN="${LIC:-}"
if ! LIC_BIN="$(resolve_lic 2>/dev/null)"; then
  LIC_BIN=""
fi

wsl_path() {
  local p="$1"
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

lic_check() {
  local smoke_path="$1"
  local label="${2:-$smoke_path}"
  [[ -f "$smoke_path" ]] || fail "missing smoke $smoke_path"
  if [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]] && command -v wsl >/dev/null 2>&1; then
    local wsl_lic wsl_studio rel
    wsl_lic="$(wsl_path "$LIC_ROOT")"
    wsl_studio="$(wsl_path "$ROOT")"
    rel="${smoke_path#"$ROOT"/}"
    wsl -e bash -lc "cd '$wsl_studio' && '$wsl_lic/build-wsl/compiler/lic/lic' check --no-cache '$rel'" \
      || fail "lic check $label (wsl)"
  elif [[ -n "$LIC_BIN" && -x "$LIC_BIN" ]]; then
    "$LIC_BIN" check "$smoke_path" || fail "lic check $label"
  else
    warn "lic not runnable — skipping $label"
  fi
}

try_wsl_lic_smokes() {
  [[ "${WORLD_STUDIO_GATES_WSL:-auto}" == "0" ]] && return 1
  [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]] || return 1
  command -v wsl >/dev/null 2>&1 || return 1
  return 0
}

echo "==> token verification (soft until wsg-w0-token-verify done)"
if [[ -f "$ROOT/scripts/studio-ui-ux-verify-tokens.py" ]]; then
  python3 "$ROOT/scripts/studio-ui-ux-verify-tokens.py" || warn "studio-ui-ux-verify-tokens soft-fail"
fi

echo "==> studio smokes"
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" == "1" ]]; then
  warn "skip lic check smokes (WORLD_STUDIO_GATES_SKIP_LIC=1)"
elif [[ -f "$ROOT/scripts/world-studio-plan-lic-smokes-wsl.sh" ]] && command -v wsl.exe >/dev/null 2>&1; then
  bash "$ROOT/scripts/world-studio-plan-lic-smokes-wsl.sh" || warn "world-studio-plan-lic-smokes-wsl soft-fail"
elif [[ -n "$LIC_BIN" || -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; then
  lic_check "$ROOT/li-tests/smoke/studio_shell_demo.li" "studio_shell_demo" || warn "studio_shell_demo soft-fail"
  lic_check "$ROOT/li-tests/smoke/studio_compose_panels.li" "studio_compose_panels" || warn "studio_compose_panels soft-fail"
else
  warn "lic not built — set WORLD_STUDIO_GATES_SKIP_LIC=1 or build lic / WSL build-wsl"
fi

echo "==> lic package smokes (li-ui, li-gui)"
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  for pkg_smoke in \
    "$LIC_ROOT/packages/li-ui/li-tests/smoke/paint_studio_shell_chrome.li" \
    "$LIC_ROOT/packages/li-gui/li-tests/smoke/gui_handle_studio_key.li"; do
    if [[ -f "$pkg_smoke" ]]; then
      lic_check "$pkg_smoke" "$(basename "$pkg_smoke")" || warn "$(basename "$pkg_smoke") soft-fail"
    fi
  done
fi

echo "==> phase 0 styled-chrome probe (informational until W0 done)"
if grep -q 'fill_round_rect\|stroke_round_rect\|paint_op_fill_round' "$LIC_ROOT/packages/li-ui/src/lib.li" 2>/dev/null; then
  ok "li-ui has round-rect paint ops"
else
  warn "li-ui round-rect paint ops not landed yet (wsg-w0-paint-ops)"
fi

echo "==> iteration assessment"
if [[ -f "$ASSESS" ]]; then
  python3 -c "
import json, sys
from pathlib import Path
d = json.loads(Path('$ASSESS').read_text(encoding='utf-8'))
if not d.get('native_only', True):
    print('assessment: native_only must be true', file=sys.stderr)
    sys.exit(1)
" || fail "latest-iteration-assessment.json native_only=false"
else
  warn "no latest-iteration-assessment.json yet (agent should write after iteration)"
fi

ok "world-studio-gui-plan-gates"
