#!/usr/bin/env bash
# Progress gates for world-studio-gui-demo-recorder (UiSnapshot + MCP + MP4).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export STUDIO_ROOT="$ROOT"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }
ok() { echo "OK: $*"; }

PLAN="$STUDIO_ROOT/docs/superpowers/plans/2026-06-03-world-studio-gui-demo-recorder-loop.md"
GOAL="$STUDIO_ROOT/data/goal-directed-sprints/world-studio-gui-demo-recorder.md"
RFC="$STUDIO_ROOT/docs/game-dev/specs/studio-gui-control-rfc.md"

[[ -f "$PLAN" ]] || fail "missing plan"
[[ -f "$GOAL" ]] || fail "missing goal"
[[ -f "$RFC" ]] || fail "missing RFC"

resolve_lic_bin() {
  local c
  for c in \
    "$LIC_ROOT/build/compiler/lic/lic" \
    "$LIC_ROOT/out/compiler/lic/lic" \
    "$(command -v lic 2>/dev/null || true)"; do
    [[ -n "$c" && -x "$c" ]] && { echo "$c"; return 0; }
  done
  return 1
}

LIC_BIN=""
if LIC_BIN="$(resolve_lic_bin)"; then ok "lic=$LIC_BIN"; else warn "lic not found — skipping smokes"; fi

run_smoke() {
  local path="$1"
  [[ -z "$LIC_BIN" ]] && return 0
  [[ -f "$path" ]] || { warn "smoke not yet added: $path"; return 0; }
  local rel=""
  if [[ "$path" == "$STUDIO_ROOT/li-tests/smoke/"* ]]; then
    rel="packages/li-studio/li-tests/smoke/$(basename "$path")"
    (cd "$LIC_ROOT" && "$LIC_BIN" check "$rel") || fail "lic check $rel"
    return 0
  fi
  if [[ "$path" == "$LIC_ROOT/packages/li-gui/"* ]]; then
    rel="${path#"$LIC_ROOT/"}"
    (cd "$LIC_ROOT" && "$LIC_BIN" check "$rel") || fail "lic check $rel"
    return 0
  fi
  "$LIC_BIN" check "$path" || fail "lic check $path"
}

# Baseline (must stay green)
for s in \
  "$STUDIO_ROOT/li-tests/smoke/studio_keyboard_bridge.li" \
  "$STUDIO_ROOT/li-tests/smoke/studio_shell_widget_tree.li" \
  "$STUDIO_ROOT/li-tests/smoke/studio_mcp_tools.li"; do
  run_smoke "$s"
done

# WREC smokes (warn until implemented)
for s in \
  "$LIC_ROOT/packages/li-gui/li-tests/smoke/ui_snapshot_shell_regions.li" \
  "$STUDIO_ROOT/li-tests/smoke/studio_ui_snapshot.li" \
  "$STUDIO_ROOT/li-tests/smoke/studio_mcp_ui_snapshot.li" \
  "$STUDIO_ROOT/li-tests/smoke/studio_demo_replay_minimal.li" \
  "$STUDIO_ROOT/li-tests/smoke/studio_demo_capture_frame.li"; do
  run_smoke "$s"
done

command -v ffmpeg >/dev/null 2>&1 || warn "ffmpeg not in PATH — W5 encode blocked locally"

ok "world-studio-gui-demo-recorder progress gates finished"
