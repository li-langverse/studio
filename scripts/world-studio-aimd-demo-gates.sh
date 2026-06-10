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

sync_studio_to_lic() {
  for smoke in studio_mcp_aimd_configure.li studio_aimd_hero_e2e.li studio_aimd_hero_runner.li \
    studio_aimd_final_viz.li studio_aimd_final_viz_capture.li; do
    if [[ -f "$STUDIO_ROOT/li-tests/smoke/$smoke" ]]; then
      cp -f "$STUDIO_ROOT/li-tests/smoke/$smoke" "$LIC_ROOT/packages/li-studio/li-tests/smoke/$smoke" 2>/dev/null || true
    fi
  done
}

PLAN="$STUDIO_ROOT/docs/superpowers/plans/2026-06-06-world-studio-aimd-demo-loop.md"
PLAN_W8="$STUDIO_ROOT/docs/superpowers/plans/2026-06-10-world-studio-aimd-dft-tunable-gpu-loop.md"
GOAL_W8="$STUDIO_ROOT/data/goal-directed-sprints/world-studio-aimd-dft-tunable-gpu.md"
GOAL_PILOT="$STUDIO_ROOT/data/goal-directed-sprints/world-studio-aimd-gpu-pilot.md"
GOAL="$STUDIO_ROOT/data/goal-directed-sprints/world-studio-aimd-demo.md"
HERO="$STUDIO_ROOT/data/world-studio-aimd-demo-loop/hero-scenario.json"
DEMO_JSON="$STUDIO_ROOT/data/demo-scripts/aimd-hero.demo.json"

[[ -f "$PLAN" ]] || fail "missing plan"
[[ -f "$PLAN_W8" ]] || warn "missing W8 plan: $PLAN_W8"
[[ -f "$GOAL_W8" ]] || warn "missing W8 goal: $GOAL_W8"
[[ -f "$GOAL" ]] || fail "missing goal"
[[ -f "$HERO" ]] || fail "missing hero scenario"
[[ -f "$DEMO_JSON" ]] || fail "missing aimd-hero.demo.json (W5)"

resolve_lic_bin() {
  resolve_lic 2>/dev/null || command -v lic 2>/dev/null || true
}

LIC_BIN=""
if LIC_BIN="$(resolve_lic_bin)"; then ok "lic=$LIC_BIN"; else warn "lic not found — skipping smokes"; fi

sync_studio_to_lic

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
  if [[ "$path" == "$LIC_ROOT/packages/"* ]]; then
    rel="${path#"$LIC_ROOT/"}"
    (cd "$LIC_ROOT" && "$LIC_BIN" check "$rel") || fail "lic check $rel"
    return 0
  fi
  if [[ "$path" == "$LIC_ROOT/"* ]]; then
    rel="${path#"$LIC_ROOT/"}"
    (cd "$LIC_ROOT" && "$LIC_BIN" check "$rel") || fail "lic check $rel"
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

# W3 / W7a GPU path — chem DFT kernel + science_gpu PH-SCI-GPU-16
if [[ -f "$LIC_ROOT/scripts/ph-sci-gpu-chem-gates.sh" ]]; then
  PH_SCI_GPU_PILOT_SUBSET="${PH_SCI_GPU_PILOT_SUBSET:-1}" \
    bash "$LIC_ROOT/scripts/ph-sci-gpu-chem-gates.sh" || fail "ph-sci-gpu-chem-gates.sh failed (W3/W7a GPU path)"
else
  fail "ph-sci-gpu-chem-gates.sh not found — W3/W7a GPU gate required"
fi

# W7a pilot trace — gpu_path must match selector (honest CPU fallback when science_gpu absent)
if [[ -n "$LIC_BIN" && -f "$LIC_ROOT/packages/li-sim-scientific/li-tests/smoke/echem_aimd_batch_smoke.li" ]]; then
  (cd "$LIC_ROOT" && "$LIC_BIN" check packages/li-sim-scientific/li-tests/smoke/echem_aimd_batch_smoke.li) \
    || fail "W7a echem_aimd_batch_smoke (gpu_path + dft_stride)"
  ok "W7a pilot batch trace smoke green"
fi

# W8b stride=1 smoke (128 steps — fast path; REAL 5000-DFT is optional completion)
if [[ -n "$LIC_BIN" && -f "$LIC_ROOT/packages/li-sim-scientific/li-tests/smoke/echem_aimd_batch_stride_smoke.li" ]]; then
  (cd "$LIC_ROOT" && "$LIC_BIN" check packages/li-sim-scientific/li-tests/smoke/echem_aimd_batch_stride_smoke.li) \
    || fail "W8b echem_aimd_batch_stride_smoke (dft_stride=1)"
  ok "W8b stride=1 batch smoke green"
fi

[[ -f "$GOAL_PILOT" ]] || warn "missing W7 pilot goal: $GOAL_PILOT"
[[ -f "$GOAL_W8" ]] || warn "missing W8 goal: $GOAL_W8"

ok "world-studio-aimd-demo progress gates finished"
