#!/usr/bin/env bash
# Run World Studio plan-loop lic check smokes (Linux/WSL or native lic on PATH).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIC="${LIC:-}"
if [[ -x "$LIC_ROOT/build/compiler/lic/lic" ]]; then
  LIC="$LIC_ROOT/build/compiler/lic/lic"
elif [[ -x "$LIC_ROOT/build-wsl/compiler/lic/lic" ]]; then
  LIC="$LIC_ROOT/build-wsl/compiler/lic/lic"
elif [[ -x "$LIC_ROOT/build/compiler/lic/lic.exe" ]]; then
  LIC="$LIC_ROOT/build/compiler/lic/lic.exe"
fi
[[ -n "$LIC" && -x "$LIC" ]] || {
  echo "world-studio-plan-lic-smokes: lic not found (build lic or set LIC=)" >&2
  exit 1
}

for smoke in env_pool_stub.li env_pool_step_contract.li env_pool_session_persistent.li; do
  "$LIC" check "$ROOT/packages/li-sim/li-tests/smoke/$smoke"
done

for smoke in scientific_oracle_bench.li run_algo_registry_tier2.li; do
  "$LIC" check "$ROOT/packages/li-sim-scientific/li-tests/smoke/$smoke"
done

"$LIC" check "$ROOT/packages/li-assets/li-tests/smoke/gltf_ingest.li"

"$LIC" check "$ROOT/packages/li-sim-robotics/li-tests/smoke/robo_ik_6dof.li"

"$LIC" check "$ROOT/packages/li-sim-additive/li-tests/smoke/sim_export_print.li"

for smoke in \
  studio_shell_demo.li \
  studio_vertical_profile_roundtrip.li \
  studio_sim_step_by_profile.li \
  studio_sim_rl_step_hook.li \
  studio_timeline_playback.li \
  studio_toml_engine_export.li \
  studio_am_export_three_click.li \
  studio_publish_figure.li \
  studio_publish_table.li \
  studio_command_palette.li \
  studio_keyboard_bridge.li \
  studio_mcp_tools.li \
  studio_mcp_dispatch_run.li \
  studio_mcp_stdio_server.li \
  studio_agentic_run.li \
  studio_agent_chrome.li \
  studio_agent_chrome_fsm.li \
  studio_interaction_modes.li \
  studio_world_checkpoint_after_tick.li \
  studio_world_io_roundtrip.li \
  studio_gltf_ingest.li \
  studio_sim_scientific_viz_viewport.li \
  studio_adaptive_litl_panel_sets.li \
  studio_sim_robotics_inspector.li \
  studio_viewport_hud.li \
  studio_viewport_error.li \
  studio_native_pixels_wgpu_readback.li \
  studio_vertical_dod.li; do
  (cd "$ROOT" && "$LIC" check "li-tests/smoke/$smoke")
done

for smoke in studio_ai_apply_patch_loop.li studio_ai_mcp_dispatch.li studio_ai_task_state.li studio_ai_patch_eval.li; do
  "$LIC" check "$ROOT-ai/li-tests/smoke/$smoke"
done

"$LIC" check "$ROOT/packages/li-player/li-tests/smoke/player_publish.li"

echo "world-studio-plan-lic-smokes: ok"
