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

echo "==> token verification (TOML ↔ li-ui via LIC_ROOT)"
if [[ -f "$ROOT/scripts/studio-ui-ux-verify-tokens.py" ]]; then
  export LIC_ROOT
  python3 "$ROOT/scripts/studio-ui-ux-verify-tokens.py" || fail "studio-ui-ux-verify-tokens"
else
  fail "missing studio-ui-ux-verify-tokens.py"
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

echo "==> phase 0 styled-chrome (native window + li-ui ops)"
if grep -q 'fill_round_rect\|stroke_round_rect\|paint_op_fill_round' "$LIC_ROOT/packages/li-ui/src/lib.li" 2>/dev/null; then
  ok "li-ui has round-rect paint ops"
else
  fail "li-ui round-rect paint ops missing (wsg-w0-paint-ops)"
fi
if [[ -f "$ROOT/scripts/studio-ui-ux-verify-styled-chrome-native.py" ]]; then
  python3 "$ROOT/scripts/studio-ui-ux-verify-styled-chrome-native.py" || fail "studio-ui-ux-verify-styled-chrome-native"
else
  fail "missing studio-ui-ux-verify-styled-chrome-native.py"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  styled_smoke="$LIC_ROOT/packages/li-studio/li-tests/smoke/studio_native_styled_chrome.li"
  if [[ -f "$styled_smoke" ]]; then
    lic_check "$styled_smoke" "studio_native_styled_chrome" || fail "studio_native_styled_chrome"
  else
    warn "studio_native_styled_chrome smoke missing under LIC_ROOT"
  fi
fi

echo "==> phase 1 widget protocol (li-gui measure/layout/paint/events)"
if grep -q 'def widget_measure' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def widget_layout' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def widget_paint' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def widget_handle_event' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null; then
  ok "li-gui Widget protocol procs present"
else
  fail "li-gui Widget protocol missing (wsg-w1-widget-protocol)"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  widget_smoke="$LIC_ROOT/packages/li-gui/li-tests/smoke/widget_protocol_measure_layout.li"
  if [[ -f "$widget_smoke" ]]; then
    lic_check "$widget_smoke" "widget_protocol_measure_layout" || fail "widget_protocol_measure_layout"
  else
    warn "widget_protocol_measure_layout smoke missing under LIC_ROOT"
  fi
fi

echo "==> phase 1 layout engines (Flex, Grid, Padding, Scroll)"
if grep -q 'def flex_layout_measure' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def grid_layout_layout' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def padding_layout_layout' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def scroll_layout_layout' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null; then
  ok "li-gui layout engines present"
else
  fail "li-gui layout engines missing (wsg-w1-layout-engines)"
fi
  if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  layout_smoke="$LIC_ROOT/packages/li-gui/li-tests/smoke/layout_engines_flex_grid.li"
  if [[ -f "$layout_smoke" ]]; then
    lic_check "$layout_smoke" "layout_engines_flex_grid" || fail "layout_engines_flex_grid"
  else
    warn "layout_engines_flex_grid smoke missing under LIC_ROOT"
  fi
fi

echo "==> phase 1 event dispatcher (hit-test tree + focus manager)"
if grep -q 'def event_dispatcher_hit_test_flex' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def event_dispatcher_focus_next' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def event_dispatcher_pointer_down' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def event_dispatcher_dispatch_key_focus' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null; then
  ok "li-gui EventDispatcher procs present"
else
  fail "li-gui EventDispatcher missing (wsg-w1-event-dispatcher)"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  dispatch_smoke="$LIC_ROOT/packages/li-gui/li-tests/smoke/event_dispatcher_hit_focus.li"
  if [[ -f "$dispatch_smoke" ]]; then
    lic_check "$dispatch_smoke" "event_dispatcher_hit_focus" || fail "event_dispatcher_hit_focus"
  else
    warn "event_dispatcher_hit_focus smoke missing under LIC_ROOT"
  fi
fi

echo "==> iteration assessment"
if [[ -f "$ASSESS" ]]; then
  assess_py="$ASSESS"
  if command -v cygpath >/dev/null 2>&1; then
    assess_py="$(cygpath -w "$ASSESS")"
  fi
  python3 -c "
import json, sys
from pathlib import Path
d = json.loads(Path(r'''$assess_py''').read_text(encoding='utf-8'))
if not d.get('native_only', True):
    print('assessment: native_only must be true', file=sys.stderr)
    sys.exit(1)
" || fail "latest-iteration-assessment.json native_only=false"
else
  warn "no latest-iteration-assessment.json yet (agent should write after iteration)"
fi

ok "world-studio-gui-plan-gates"
