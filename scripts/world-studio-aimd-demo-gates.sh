#!/usr/bin/env bash
# Progress gates for world-studio-aimd-demo (agent MCP + batch AIMD + final viz).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export STUDIO_ROOT="$ROOT"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }
ok() { echo "OK: $*"; }

PLAN="$STUDIO_ROOT/docs/superpowers/plans/2026-06-06-world-studio-aimd-demo-loop.md"
GOAL="$STUDIO_ROOT/data/goal-directed-sprints/world-studio-aimd-demo.md"
HERO="$STUDIO_ROOT/data/world-studio-aimd-demo-loop/hero-scenario.json"
DEMO_JSON="$STUDIO_ROOT/data/demo-scripts/aimd-hero.demo.json"

[[ -f "$PLAN" ]] || fail "missing plan"
[[ -f "$GOAL" ]] || fail "missing goal"
[[ -f "$HERO" ]] || fail "missing hero scenario"
[[ -f "$DEMO_JSON" ]] || fail "missing aimd-hero.demo.json (W5)"

resolve_lic_bin() {
  resolve_lic 2>/dev/null || command -v lic 2>/dev/null || true
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
    (cd "$LIC_ROOT" && "$LIC_BIN" check "$rel" --workspace=packages/li.toml) || fail "lic check $rel"
    return 0
  fi
  if [[ "$path" == "$LIC_ROOT/packages/"* ]]; then
    rel="${path#"$LIC_ROOT/"}"
    (cd "$LIC_ROOT" && "$LIC_BIN" check "$rel" --workspace=packages/li.toml) || fail "lic check $rel"
    return 0
  fi
  "$LIC_BIN" check "$path" || fail "lic check $path"
}

# Baseline (must stay green)
for s in \
  "$STUDIO_ROOT/li-tests/smoke/studio_mcp_tools.li" \
  "$STUDIO_ROOT/li-tests/smoke/studio_mcp_dispatch_run.li" \
  "$STUDIO_ROOT/li-tests/smoke/studio_vertical_dod_sim_scientific_composable.li"; do
  run_smoke "$s"
done

# AIMD foundation (extend as WPs land)
for s in \
  "$LIC_ROOT/packages/li-sim-scientific/li-tests/smoke/echem_aimd_interface_smoke.li" \
  "$LIC_ROOT/li-tests/composable/import_echem_aimd_smoke.li" \
  "$STUDIO_ROOT/li-tests/smoke/studio_mcp_aimd_configure.li" \
  "$LIC_ROOT/packages/li-sim-scientific/li-tests/smoke/echem_aimd_batch_smoke.li" \
  "$STUDIO_ROOT/li-tests/smoke/studio_aimd_final_viz.li" \
  "$STUDIO_ROOT/li-tests/smoke/studio_aimd_hero_e2e.li"; do
  run_smoke "$s"
done

# W3 GPU path — chem DFT kernel + science_gpu PH-SCI-GPU-16 (optional when script absent; stub tier documented)
if [[ -x "$LIC_ROOT/scripts/ph-sci-gpu-chem-gates.sh" ]]; then
  bash "$LIC_ROOT/scripts/ph-sci-gpu-chem-gates.sh" || fail "ph-sci-gpu-chem-gates.sh failed (W3 GPU path)"
else
  warn "ph-sci-gpu-chem-gates.sh not found — W3 GPU gate deferred (cpu stub tier)"
fi

ok "world-studio-aimd-demo progress gates finished"
