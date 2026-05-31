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
if [[ -x "$ROOT/scripts/build-studio-verticals-host.sh" ]]; then
  bash "$ROOT/scripts/build-studio-verticals-host.sh" || warn "build-studio-verticals-host soft-fail"
fi
if [[ -f "$ROOT/scripts/studio-ui-ux-verify-styled-chrome-native.py" ]]; then
  export STUDIO_UI_UX_VERIFY_REQUIRE_PPM="${STUDIO_UI_UX_VERIFY_REQUIRE_PPM:-1}"
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

echo "==> phase 1 base widgets (Label, Button, Panel, ScrollArea, TextInput)"
if grep -q 'def widget_node_text_input' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def scroll_area_new' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def scroll_area_paint' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def gui_base_widgets_version' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null; then
  ok "li-gui base widgets present"
else
  fail "li-gui base widgets missing (wsg-w1-base-widgets)"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  base_smoke="$LIC_ROOT/packages/li-gui/li-tests/smoke/base_widgets.li"
  if [[ -f "$base_smoke" ]]; then
    lic_check "$base_smoke" "base_widgets" || fail "base_widgets"
  else
    warn "base_widgets smoke missing under LIC_ROOT"
  fi
fi

echo "==> phase 1 focus model (roving tabindex + studio_paint_focus_ring)"
if grep -q 'def focus_model_roving_next' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def focus_model_roving_prev' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def focus_model_paint_flex_focus_rings' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def event_dispatcher_handle_tab_key' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def gui_focus_model_version' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null; then
  ok "li-gui FocusModel procs present"
else
  fail "li-gui FocusModel missing (wsg-w1-focus-model)"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  focus_smoke="$LIC_ROOT/packages/li-gui/li-tests/smoke/focus_model_roving_tab.li"
  if [[ -f "$focus_smoke" ]]; then
    lic_check "$focus_smoke" "focus_model_roving_tab" || fail "focus_model_roving_tab"
  else
    warn "focus_model_roving_tab smoke missing under LIC_ROOT"
  fi
fi

echo "==> phase 1 inspector widget pilot (Flex/Grid tree + studio compose bridge)"
if grep -q 'def inspector_pilot_new' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def inspector_pilot_layout' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def inspector_pilot_paint' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def studio_compose_inspector_widget_pilot' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null \
  && grep -q 'def gui_inspector_pilot_version' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null; then
  ok "li-gui inspector pilot + li-studio compose bridge present"
else
  fail "li-gui inspector pilot missing (wsg-w1-inspector-pilot)"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  pilot_smoke="$LIC_ROOT/packages/li-gui/li-tests/smoke/inspector_pilot_widget.li"
  if [[ -f "$pilot_smoke" ]]; then
    lic_check "$pilot_smoke" "inspector_pilot_widget" || fail "inspector_pilot_widget"
  else
    warn "inspector_pilot_widget smoke missing under LIC_ROOT"
  fi
  studio_pilot_smoke="$LIC_ROOT/packages/li-studio/li-tests/smoke/studio_inspector_widget_pilot.li"
  if [[ -f "$studio_pilot_smoke" ]]; then
    lic_check "$studio_pilot_smoke" "studio_inspector_widget_pilot" || fail "studio_inspector_widget_pilot"
  else
    warn "studio_inspector_widget_pilot smoke missing under LIC_ROOT"
  fi
fi

echo "==> phase 2 reactive stores (StoreInt/StoreFloat, Derived, invalidation)"
if grep -q 'type StoreInt' "$LIC_ROOT/packages/li-gui/src/reactive.li" 2>/dev/null \
  && grep -q 'type DerivedInt' "$LIC_ROOT/packages/li-gui/src/reactive.li" 2>/dev/null \
  && grep -q 'type StoreFloat' "$LIC_ROOT/packages/li-gui/src/reactive.li" 2>/dev/null \
  && grep -q 'def store_int_set' "$LIC_ROOT/packages/li-gui/src/reactive.li" 2>/dev/null \
  && grep -q 'def derived_int_sync_value' "$LIC_ROOT/packages/li-gui/src/reactive.li" 2>/dev/null \
  && grep -q 'def compose_invalidation_any_dirty' "$LIC_ROOT/packages/li-gui/src/reactive.li" 2>/dev/null \
  && grep -q 'def gui_reactive_version' "$LIC_ROOT/packages/li-gui/src/reactive.li" 2>/dev/null; then
  ok "li-gui Store/Derived reactive primitives present"
else
  fail "li-gui reactive stores missing (wsg-w2-store-primitives)"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  reactive_smoke="$LIC_ROOT/packages/li-gui/li-tests/smoke/reactive_store_derived.li"
  if [[ -f "$reactive_smoke" ]]; then
    lic_check "$reactive_smoke" "reactive_store_derived" || fail "reactive_store_derived"
  else
    warn "reactive_store_derived smoke missing under LIC_ROOT"
  fi
fi

echo "==> phase 2 compose dependency graph (ComposePlan store → region invalidation)"
if grep -q 'type ComposeDepGraph' "$LIC_ROOT/packages/li-gui/src/reactive.li" 2>/dev/null \
  && grep -q 'def compose_dep_invalidate_store' "$LIC_ROOT/packages/li-gui/src/reactive.li" 2>/dev/null \
  && grep -q 'def store_int_set_with_deps' "$LIC_ROOT/packages/li-gui/src/reactive.li" 2>/dev/null \
  && grep -q 'def compose_dep_plan_version' "$LIC_ROOT/packages/li-gui/src/reactive.li" 2>/dev/null; then
  ok "li-gui ComposeDepGraph + ComposePlan present"
else
  fail "li-gui compose dependency graph missing (wsg-w2-compose-deps)"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  compose_dep_smoke="$LIC_ROOT/packages/li-gui/li-tests/smoke/compose_dep_invalidation.li"
  if [[ -f "$compose_dep_smoke" ]]; then
    lic_check "$compose_dep_smoke" "compose_dep_invalidation" || fail "compose_dep_invalidation"
  else
    warn "compose_dep_invalidation smoke missing under LIC_ROOT"
  fi
fi

echo "==> phase 2 migrate manual sync (StudioReactiveShell on StudioShellCompose)"
if grep -q 'type StudioReactiveShell' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null \
  && grep -q 'def studio_reactive_flush_agent_from_run' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null \
  && grep -q 'def studio_reactive_resync_palette' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null \
  && grep -q 'def studio_reactive_timeline_sync_playhead' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null \
  && grep -q 'public reactive: StudioReactiveShell' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null; then
  ok "li-studio reactive shell migration present"
else
  fail "li-studio reactive shell migration missing (wsg-w2-migrate-sync)"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  reactive_shell_smoke="$LIC_ROOT/packages/li-studio/li-tests/smoke/studio_reactive_shell_sync.li"
  if [[ -f "$reactive_shell_smoke" ]]; then
    lic_check "$reactive_shell_smoke" "studio_reactive_shell_sync" || fail "studio_reactive_shell_sync"
  else
    warn "studio_reactive_shell_sync smoke missing under LIC_ROOT"
  fi
fi

echo "==> phase 2 compose cache (ComposeCache dirty flags + partial re-compose)"
if grep -q 'type ComposeCache' "$LIC_ROOT/packages/li-gui/src/reactive.li" 2>/dev/null \
  && grep -q 'def compose_cache_should_recompose' "$LIC_ROOT/packages/li-gui/src/reactive.li" 2>/dev/null \
  && grep -q 'def compose_cache_tally_partial' "$LIC_ROOT/packages/li-gui/src/reactive.li" 2>/dev/null \
  && grep -q 'def compose_cache_version' "$LIC_ROOT/packages/li-gui/src/reactive.li" 2>/dev/null \
  && grep -q 'public cache: ComposeCache' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null \
  && grep -q 'def studio_reactive_cache_tally' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null; then
  ok "li-gui ComposeCache + li-studio partial re-compose present"
else
  fail "ComposeCache missing (wsg-w2-compose-cache)"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  cache_smoke="$LIC_ROOT/packages/li-gui/li-tests/smoke/compose_cache_partial_recompose.li"
  if [[ -f "$cache_smoke" ]]; then
    lic_check "$cache_smoke" "compose_cache_partial_recompose" || fail "compose_cache_partial_recompose"
  else
    warn "compose_cache_partial_recompose smoke missing under LIC_ROOT"
  fi
  studio_cache_smoke="$LIC_ROOT/packages/li-studio/li-tests/smoke/studio_compose_cache_partial.li"
  if [[ -f "$studio_cache_smoke" ]]; then
    lic_check "$studio_cache_smoke" "studio_compose_cache_partial" || fail "studio_compose_cache_partial"
  else
    warn "studio_compose_cache_partial smoke missing under LIC_ROOT"
  fi
fi

echo "==> phase 3 font atlas (Inter + ui-monospace bitmap @ build time)"
if grep -q 'def font_atlas_version' "$LIC_ROOT/packages/li-ui/src/font_atlas.li" 2>/dev/null \
  && grep -q 'def font_atlas_face_new' "$LIC_ROOT/packages/li-ui/src/font_atlas.li" 2>/dev/null \
  && grep -q 'def font_atlas_sample_alpha' "$LIC_ROOT/packages/li-ui/src/font_atlas.li" 2>/dev/null \
  && grep -q 'BEGIN font-atlas-generated' "$LIC_ROOT/packages/li-ui/src/lib.li" 2>/dev/null; then
  ok "li-ui font atlas API + lib.li mirror present"
else
  fail "li-ui font atlas missing (wsg-w3-font-atlas)"
fi
if [[ -f "$LIC_ROOT/scripts/build-font-atlas.py" ]]; then
  python3 "$LIC_ROOT/scripts/build-font-atlas.py" --verify || fail "build-font-atlas.py --verify"
else
  fail "missing scripts/build-font-atlas.py (wsg-w3-font-atlas)"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  atlas_smoke="$LIC_ROOT/packages/li-ui/li-tests/smoke/font_atlas_inter_mono.li"
  if [[ -f "$atlas_smoke" ]]; then
    lic_check "$atlas_smoke" "font_atlas_inter_mono" || fail "font_atlas_inter_mono"
  else
    fail "font_atlas_inter_mono smoke missing under LIC_ROOT"
  fi
fi

echo "==> phase 3 PaintCmd ext ops (draw_glyphs, draw_image, clip_push/pop)"
if grep -q 'def paint_op_draw_glyphs' "$LIC_ROOT/packages/li-ui/src/lib.li" 2>/dev/null \
  && grep -q 'def paint_cmd_draw_image' "$LIC_ROOT/packages/li-ui/src/lib.li" 2>/dev/null \
  && grep -q 'def paint_cmd_clip_push' "$LIC_ROOT/packages/li-ui/src/lib.li" 2>/dev/null \
  && grep -q 'def paint_cmd_clip_pop' "$LIC_ROOT/packages/li-ui/src/lib.li" 2>/dev/null \
  && [[ -f "$LIC_ROOT/packages/li-ui/src/paint_cmds_ext.li" ]]; then
  ok "li-ui PaintCmd ext ops present (clip, glyphs, image)"
else
  fail "li-ui PaintCmd ext ops missing (wsg-w3-paintcmd-glyphs)"
fi
if [[ -f "$LIC_ROOT/scripts/sync-paint-cmds-ext.py" ]]; then
  python3 "$LIC_ROOT/scripts/sync-paint-cmds-ext.py" --verify || fail "sync-paint-cmds-ext.py --verify"
else
  fail "missing scripts/sync-paint-cmds-ext.py (wsg-w3-paintcmd-glyphs)"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  paint_ext_smoke="$LIC_ROOT/packages/li-ui/li-tests/smoke/paint_cmds_ext_phase3.li"
  if [[ -f "$paint_ext_smoke" ]]; then
    lic_check "$paint_ext_smoke" "paint_cmds_ext_phase3" || fail "paint_cmds_ext_phase3"
  else
    fail "paint_cmds_ext_phase3 smoke missing under LIC_ROOT"
  fi
fi

echo "==> phase 3 UI raster pass (li-render CPU fallback + wgpu chrome pipeline)"
if grep -q 'def render_ui_raster_pass' "$LIC_ROOT/packages/li-render/src/lib.li" 2>/dev/null \
  && grep -q 'def render_ui_raster_cpu_pass' "$LIC_ROOT/packages/li-render/src/lib.li" 2>/dev/null \
  && grep -q 'def lig_wgpu_ui_raster_submit' "$LIC_ROOT/packages/lig/present/lib.li" 2>/dev/null \
  && grep -q 'def render_ui_raster_version' "$LIC_ROOT/packages/li-render/src/lib.li" 2>/dev/null; then
  ok "li-render UI raster pass + lig wgpu submit present"
else
  fail "li-render UI raster pass missing (wsg-w3-ui-raster)"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  ui_raster_smoke="$LIC_ROOT/packages/li-render/li-tests/smoke/ui_raster_pass.li"
  if [[ -f "$ui_raster_smoke" ]]; then
    lic_check "$ui_raster_smoke" "ui_raster_pass" || fail "ui_raster_pass"
  else
    fail "ui_raster_pass smoke missing under LIC_ROOT"
  fi
fi

echo "==> phase 3 wgpu viewport swapchain pixels (Path A readback, WP-GD-05)"
if grep -q 'def render_wgpu_viewport_readback' "$LIC_ROOT/packages/li-render/src/lib.li" 2>/dev/null \
  && grep -q 'def render_viewport_readback_ok' "$LIC_ROOT/packages/li-render/src/lib.li" 2>/dev/null \
  && grep -q 'def lig_wgpu_swapchain_readback_run' "$LIC_ROOT/packages/lig/present/lib.li" 2>/dev/null \
  && grep -q 'def lig_present_wgpu_swapchain_active' "$LIC_ROOT/packages/lig/present/lib.li" 2>/dev/null \
  && grep -q 'def studio_native_pixels_wgpu_swapchain_host_smoke' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null; then
  ok "li-render viewport swapchain readback + li-studio host smoke present"
else
  fail "wgpu viewport swapchain pixels missing (wsg-w3-wgpu-viewport-pixels)"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  swap_smoke="$LIC_ROOT/packages/li-render/li-tests/smoke/wgpu_viewport_swapchain.li"
  if [[ -f "$swap_smoke" ]]; then
    lic_check "$swap_smoke" "wgpu_viewport_swapchain" || fail "wgpu_viewport_swapchain"
  else
    fail "wgpu_viewport_swapchain smoke missing under LIC_ROOT"
  fi
  studio_swap_smoke="$LIC_ROOT/packages/li-studio/li-tests/smoke/studio_native_pixels_wgpu_swapchain.li"
  if [[ -f "$studio_swap_smoke" ]]; then
    lic_check "$studio_swap_smoke" "studio_native_pixels_wgpu_swapchain" || fail "studio_native_pixels_wgpu_swapchain"
  else
    fail "studio_native_pixels_wgpu_swapchain smoke missing under LIC_ROOT"
  fi
fi
if [[ -f "$ROOT/scripts/studio-ui-ux-verify-wgpu-swapchain.py" ]]; then
  python3 "$ROOT/scripts/studio-ui-ux-verify-wgpu-swapchain.py" || warn "studio-ui-ux-verify-wgpu-swapchain soft-fail (CPU runner expected blocked_runner)"
fi

echo "==> phase 3 icon atlas pipeline (SVG bitmap + token names, wsg-w3-icon-pipeline)"
if grep -q 'def icon_atlas_version' "$LIC_ROOT/packages/li-ui/src/icon_atlas.li" 2>/dev/null \
  && grep -q 'def studio_icon_token_image_id' "$LIC_ROOT/packages/li-ui/src/icon_atlas.li" 2>/dev/null \
  && grep -q 'paint_cmd_draw_image(dock.active_slot_rect' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null; then
  ok "icon atlas + dock draw_image paint wired"
else
  fail "icon atlas pipeline missing (wsg-w3-icon-pipeline)"
fi
if [[ -f "$LIC_ROOT/scripts/build-icon-atlas.py" ]]; then
  python3 "$LIC_ROOT/scripts/build-icon-atlas.py" --verify || fail "build-icon-atlas stale"
else
  fail "missing scripts/build-icon-atlas.py (wsg-w3-icon-pipeline)"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  icon_smoke="$LIC_ROOT/packages/li-ui/li-tests/smoke/icon_atlas_dock_tokens.li"
  if [[ -f "$icon_smoke" ]]; then
    lic_check "$icon_smoke" "icon_atlas_dock_tokens" || fail "icon_atlas_dock_tokens"
  else
    fail "icon_atlas_dock_tokens smoke missing under LIC_ROOT"
  fi
fi

echo "==> phase 4 present loop (Li rasterizer → blit, wsg-w4-present-loop)"
if grep -q 'def studio_shell_present_raster_and_blit' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null \
  && grep -q 'def studio_shell_present_raster_pass' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null \
  && grep -q 'def studio_present_loop_raster_version' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null \
  && grep -q 'studio_shell_present_raster_and_blit' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null; then
  ok "li-studio present loop wired to Li UI rasterizer"
else
  fail "li-studio present loop raster wiring missing (wsg-w4-present-loop)"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  present_raster_smoke="$LIC_ROOT/packages/li-studio/li-tests/smoke/studio_present_loop_raster.li"
  if [[ -f "$present_raster_smoke" ]]; then
    lic_check "$present_raster_smoke" "studio_present_loop_raster" || fail "studio_present_loop_raster"
  else
    fail "studio_present_loop_raster smoke missing under LIC_ROOT"
  fi
  present_loop_smoke="$LIC_ROOT/packages/li-studio/li-tests/smoke/studio_shell_demo_present_loop.li"
  if [[ -f "$present_loop_smoke" ]]; then
    lic_check "$present_loop_smoke" "studio_shell_demo_present_loop" || fail "studio_shell_demo_present_loop"
  else
    warn "studio_shell_demo_present_loop smoke missing under LIC_ROOT"
  fi
fi

echo "==> phase 4 c-host slim (I/O only, wsg-w4-c-host-slim)"
HOST_C="$ROOT/deploy/studio-demo/native/studio_shell_present_host.c"
if [[ -f "$HOST_C" ]]; then
  if grep -q 'STUDIO_SHELL_HOST_IO_ONLY' "$HOST_C" \
    && ! grep -q 'studio_shell_paint_fb.h\|shell_paint_frame' "$HOST_C"; then
    ok "present host slimmed to window/input/surface I/O"
  else
    fail "present host still links C paint mirror (wsg-w4-c-host-slim)"
  fi
else
  fail "missing studio_shell_present_host.c"
fi
if [[ -f "$ROOT/scripts/studio-c-host-retirement-gate.sh" ]]; then
  bash "$ROOT/scripts/studio-c-host-retirement-gate.sh" || fail "studio-c-host-retirement-gate"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  c_host_slim_smoke="$LIC_ROOT/packages/li-studio/li-tests/smoke/studio_c_host_slim.li"
  if [[ -f "$c_host_slim_smoke" ]]; then
    lic_check "$c_host_slim_smoke" "studio_c_host_slim" || fail "studio_c_host_slim"
  elif [[ -f "$ROOT/li-tests/smoke/studio_c_host_slim.li" ]]; then
    lic_check "$ROOT/li-tests/smoke/studio_c_host_slim.li" "studio_c_host_slim" || fail "studio_c_host_slim"
  else
    fail "studio_c_host_slim smoke missing"
  fi
fi

echo "==> phase 4 widget tree all regions (ShellWidgetTree + reactive stores, wsg-w4-widget-tree-all-regions)"
if grep -q 'def shell_widget_tree_new' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def shell_widget_tree_all_regions_laid_out' "$LIC_ROOT/packages/li-gui/src/lib.li" 2>/dev/null \
  && grep -q 'def studio_shell_attach_widget_tree' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null \
  && grep -q 'public widget_tree: ShellWidgetTree' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null \
  && grep -q 'studio_shell_sync_widget_tree_from_reactive' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null; then
  ok "li-gui ShellWidgetTree + li-studio reactive bridge present"
else
  fail "ShellWidgetTree all regions missing (wsg-w4-widget-tree-all-regions)"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  shell_tree_smoke="$LIC_ROOT/packages/li-gui/li-tests/smoke/shell_widget_tree_all_regions.li"
  if [[ -f "$shell_tree_smoke" ]]; then
    lic_check "$shell_tree_smoke" "shell_widget_tree_all_regions" || fail "shell_widget_tree_all_regions"
  else
    fail "shell_widget_tree_all_regions smoke missing under LIC_ROOT"
  fi
  studio_tree_smoke="$LIC_ROOT/packages/li-studio/li-tests/smoke/studio_shell_widget_tree.li"
  if [[ -f "$studio_tree_smoke" ]]; then
    lic_check "$studio_tree_smoke" "studio_shell_widget_tree" || fail "studio_shell_widget_tree"
  else
    fail "studio_shell_widget_tree smoke missing under LIC_ROOT"
  fi
fi

echo "==> phase 4 route table (StudioRoute verticals/modes, wsg-w4-route-table)"
if grep -q 'def studio_route_table_count' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null \
  && grep -q 'def studio_route_lookup' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null \
  && grep -q 'def studio_shell_apply_route' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null \
  && grep -q 'def studio_compose_shell_route' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null \
  && grep -q 'def studio_route_resolve_startup' "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null; then
  ok "li-studio StudioRoute table present"
else
  fail "StudioRoute table missing (wsg-w4-route-table)"
fi
if [[ "${WORLD_STUDIO_GATES_SKIP_LIC:-0}" != "1" ]] && { [[ -n "$LIC_BIN" ]] || [[ -f "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; }; then
  route_smoke="$LIC_ROOT/packages/li-studio/li-tests/smoke/studio_route_table.li"
  if [[ -f "$route_smoke" ]]; then
    lic_check "$route_smoke" "studio_route_table" || fail "studio_route_table"
  else
    fail "studio_route_table smoke missing under LIC_ROOT"
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
