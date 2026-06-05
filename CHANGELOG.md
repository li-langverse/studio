# Changelog

## [Unreleased]

### Added

- **World Studio GUI product-visual W5 (acceptance)** — Li headless `studio_vertical_capture_ppm_auto` in studio package; eight acceptance PNGs (seven verticals @ 640×360 + game 1280×720); completion gate + smokes `studio_product_visual_w5_acceptance.li`; `li_std_studio_version` → 49 — [2026-06-02-world-studio-gui-product-visual-w5.md](docs/release-notes/2026-06-02-world-studio-gui-product-visual-w5.md).
- **World Studio GUI polish W5 (screenshot gate)** — `polish-*.png` at 1280×720 (game, sim_rl, sim_drug_design); paint_blit shell shadows/glyphs/viewport previews; completion gate PNG color decode fix; sprint `wsp-w*` all done.
- **World Studio GUI polish W4 (slick native pass)** — panel shadows, 4/8px spacing rhythm, topbar profile accent strip, drug viewport stick preview; smokes `studio_polish_w4_{shadows_spacing,vertical_chrome}.li`; `li_std_studio_version` → 45.
- **World Studio GUI polish W0–W2 (native chrome)** — typography glyphs on outliner/dock/topbar/inspector; atlas dock icons + viewport HUD + inspector field labels; pointer hover on dock/outliner/timeline, panel focus ring, command-palette shortcut hints; smokes `studio_polish_w0_typography.li`, `studio_polish_w1_glyphs.li`, `studio_polish_w2_{hover,focus_ring,shortcut_hints}.li`; `li_std_studio_version` → 42 — [2026-06-01-world-studio-gui-polish-w0-w2.md](docs/release-notes/2026-06-01-world-studio-gui-polish-w0-w2.md) (plan: [studio#18](https://github.com/li-langverse/studio/pull/18)).
- **wsg-w5-perf-budgets PH-UX perf budgets** — release notes `docs/release-notes/2026-06-01-wsg-w5-perf-budgets.md`, `benchmarks/competitive/studio-ui.toml` v2, `studio_perf_budgets_*` API + smoke `studio_perf_budgets.li`, `verify-perf-budgets.py`; `li_std_studio_version` → 39.
- **wsg-w5-macos-wgpu macOS Metal wgpu surface** — `studio_macos_wgpu_present_version`, `studio_macos_wgpu_surface_smoke`; macOS build/launch scripts, `lig_macos_wgpu_surface_probe.c`, CI `macos-wgpu-surface-smoke` on `macos-14`; smoke `studio_macos_wgpu_present.li`.
- **WP-PUB-03 publish_bundle reproducibility manifest** — `studio_publish_bundle`, `studio_publish_bundle_three_click_flow` (Select → lic build proof → Export zip manifest); MCP `publish_bundle` writes manifest contract after proof pass; smoke `studio_publish_bundle.li`; `li_std_studio_version` → 31.
- **WP-PUB-02 studio.publish.table scientific export** — `studio_publish_table`, `studio_publish_table_from_viz_tick`, `studio_publish_table_three_click_flow` (Select → lic build proof → Export); HDF5/CSV contract from sim.viz pipeline rows; smoke `studio_publish_table.li`; `li_std_studio_version` → 30.
- **WP-PUB-01 studio.publish.figure vector export** — `studio_publish_figure`, `studio_publish_three_click_flow` (Select → lic build proof → Export); SVG/PDF/300+dpi PNG contract with journal templates; smoke `studio_publish_figure.li`; `li_std_studio_version` → 29.
- **WP-DRUG-03 adaptive LITL panel sets** — `studio_adaptive_panel_region_for_litl_stage`, `studio_shell_apply_adaptive_panel_set`; drug compose switches panel focus per LITL stage; smoke `studio_adaptive_litl_panel_sets.li`; `li_std_studio_version` → 28.
- **WP-AM-03 / WP-UX-16 AM export print + ≤3-click wizard** — `sim_export_print` in `li-sim-additive`; `studio_am_export_three_click_flow` (Review → Pre-flight → Export); MCP `am_export_print` runs print contract; smokes `sim_export_print.li`, `studio_am_export_three_click.li`; `li_std_studio_version` → 27.
- **WP-ROBO-03 / WP-UX-03 6-DOF IK + live inspector** — `studio_sim_robotics_step_hook`, `studio_compose_inspector_robotics_live`, `studio_sim_robotics_inspector_live_ok`; smokes `studio_sim_robotics_inspector.li`; extended `studio_sim_step_by_profile.li`; `li_std_studio_version` → 26.
- **WP-SCI-04 sim.viz pipeline → viewport fields** — `import sim.viz`; `studio_viewport_display_apply_viz_pipeline`, `studio_sim_scientific_viz_viewport_ok`, `studio_viz_tick_for_particle_tier`; scientific compose applies viz panel state to particle dots; smoke `studio_sim_scientific_viz_viewport.li`; `li_std_studio_version` → 25.
- **WP-GD-04 glTF ingest** — `li-assets` + `studio_shell_apply_gltf_ingest`; smoke `studio_gltf_ingest.li`; `li_std_studio_version` → 24.
- **WP-GD-02 world checkpoint after sim tick** — `StudioWorldCheckpoint` on shell; `studio_world_checkpoint_after_sim_tick` in `studio_sim_step_hook`; timeline stores checkpoint via `studio_shell_timeline_tick_sim_step`; smoke `studio_world_checkpoint_after_tick.li`.
- **WP-AG-03 MCP stdio server** — `studio_mcp_server_*` handlers, `scripts/lis-mcp-li-engine.py` + `.sh`, integration smoke; `studio_ai_mcp_dispatch` wired; smokes `studio_mcp_stdio_server.li`, `studio_ai_mcp_dispatch.li`; `li_std_studio_version` → 21.
- **WP-UX-15 interaction modes FSM** — `StudioShellCompose.mode`, `studio_mode_transition`, `studio_shell_apply_mode`, `studio_mode_mcp_tool_allowed`, `studio_shell_timeline_tick_sim_step`; smokes `studio_interaction_modes.li`; `li_std_studio_version` → 22.

- **WP-UX-14 native_pixels wgpu honesty** — `lig_native_pixel_source_honest_product`; vertical demo accepts wgpu readback/draw-list sources; draw-list submit when `LIG_WGPU_READBACK=1`; HUD host fps counter; smokes `studio_native_pixels_honesty.li`; `li_std_studio_version` → 19.
- **WP-UX-08 viewport error overlay + retry** — `studio_viewport_error_kind_for_render_smoke`, `studio_viewport_error_sync_render`, `studio_shell_handle_viewport_error_pointer`; li-render wgpu fail → GPU error strip; smoke `studio_viewport_error.li`; `li_std_studio_version` → 18.

- **WP-UX-06 / WP-AG-02 agent chrome FSM** — `studio_agent_run_cancel`, `studio_agent_run_fail`, `studio_agent_run_retry`, `studio_agent_run_undo`, `studio_agent_sync_chrome_from_run`, `studio_shell_handle_agent_pointer`, `studio_shell_agent_run_tick`; invoke + tool-trace paint; smoke `studio_agent_chrome_fsm.li`; `li_std_studio_version` → 16.

- **WP-UX-09 keyboard bridge** — `studio_shell_input_probe_mock_*`, `studio_shell_handle_host_key`; demo/host frames apply keys on live compose; smoke `studio_keyboard_bridge.li`; `li_std_studio_version` → 15.

- **WP-UX-04 command palette actions** — `studio_palette_action_*`, `studio_palette_exec_slot`, `studio_key_action_palette_exec`, `studio_palette_apply_action`; digits 1–3 run focus actions when palette open; smoke `studio_command_palette.li` extended with Cmd+K + exec path; `li_std_studio_version` → 14.

- **WP-UX-02 / WP-GD-08 timeline ↔ sim tick** — `studio_timeline_tick_sim_step`, `studio_timeline_sync_playhead_from_session`, `studio_timeline_scrub_to_tick`, `studio_timeline_reset_for_session`; playhead from `SimSessionStub.tick` / `studio_timeline_duration_ticks_default()` (not mock +0.01); runtime `li_rt_studio_timeline_sync_sim_tick`; smoke `studio_timeline_playback.li`; `li_std_studio_version` → 13.

- **WP-SIM-06 studio.toml engine/export** — `StudioExportConfig`, cumulative `studio_toml_parse_line` / `studio_toml_parsed_config`, `determinism_tier` → `output_detail` via `studio_apply_config_to_sim`; fixture `examples/verticals/sim_additive/studio.toml`; smoke `studio_toml_engine_export.li`; `li_std_studio_version` → 12.
- **PH-AGENT-2 Studio agent run state:** `StudioAgentRun`, `studio_agent_run_start`, `studio_agent_run_next`, `studio_agent_run_complete`, and `studio_agent_tool_request_for_run` model the in-process world-patch → `lic_check` → `lic_build` tool sequence with `used_html_mock == 0`; smokes `studio_agentic_run.li` and root `import_studio_agentic_run.li`; `li_std_studio_version` → 11.
- **PH-SIM scientific viewport sync** — `studio_sim_scientific_step_hook`, `studio_sim_scientific_tier_for_tick`; `sim_scientific` profile runs `sim_scientific_tick_at` + `scene_bench_particle_tier_simulate` and syncs tier/draw_points into viewport display; smoke `studio_sim_scientific_step_hook.li`; `li_std_studio_version` → 10.
- **PH-SIM SIM-3 studio RL step** — `studio_sim_rl_step_hook`; `sim_rl` in `studio_sim_step_hook` uses `sim_rl_session_env_pool_step` on live session; smokes `studio_sim_rl_step_hook.li`, extended `studio_sim_step_by_profile.li` — [2026-05-27-studio-sim-rl-env-pool-step.md](../../docs/release-notes/2026-05-27-studio-sim-rl-env-pool-step.md).
- **PH-SIM SIM-5 sensor bus** — `studio_sim_sensor_step_hook`; `sim_automotive` / `sim_robotics` use `sim_sensor_session_bus_step` via `li-sim-sensors`; smokes `studio_sim_sensor_step_hook.li`, extended `studio_sim_step_by_profile.li`.
- **PH-GAME-01 session game physics** — `studio_game_step_hook(sim_out, dt)` + `game_physics_step_hook`; smokes assert `game_pz` / `game_physics_steps` — [2026-05-27-studio-game-session-physics.md](../../docs/release-notes/2026-05-27-studio-game-session-physics.md).

- **PH-GD-2 game checkpoint roundtrip** — `studio_game_world_checkpoint_from_session`, `studio_game_world_checkpoint_stub`, `studio_game_world_checkpoint_roundtrip` (`li-world` buffer seam); smoke `studio_game_step_hook.li` — [2026-05-27-vertical-game-checkpoint-roundtrip.md](docs/release-notes/2026-05-27-vertical-game-checkpoint-roundtrip.md).

- **Vertical gap #4/#9 sim step physics** — `sim_scientific_tick_stub`, `studio_game_step_hook`, `studio_md_particle_tier_select_ok`, smokes `studio_sim_step_by_profile.li` / `import_studio_sim_step_by_profile.li` — [2026-05-25-vertical-gap-sim-step-physics.md](docs/release-notes/2026-05-25-vertical-gap-sim-step-physics.md).


### Fixed

- **Gap-close wave1 smokes** — `src/lib.li` passes `lic check` with all `li-tests/smoke/*.li` (timeline extern, move/copy fixes, MCP/viewport `raises IO`, inspector ensures); see `docs/release-notes/2026-05-25-studio-gap-close-wave1-smokes.md`.

### Added

- **Demo loop tick** — `STUDIO_DEMO_LOOP_TICK` / `li_rt_studio_demo_loop_tick_from_env`; interactive `studio-shell-demo-interactive.sh` cycles patterns 0→1→2; smoke `studio_shell_demo_pattern_tick.li`.
- **PH-HW WP3 host present** — `studio_shell_input_from_host`, `studio_shell_host_frame`, `studio_shell_host_present_loop_tick`; `li_std_studio_version` → 6; smoke `studio_host_present.li`.
- **`li-studio-demo` present loop** — `studio_shell_demo_present_loop`, `STUDIO_DEMO_FRAMES`, host input on `studio_vertical_demo_frame`; `scripts/studio-shell-demo-present-loop.sh`; smoke `studio_shell_demo_present_loop.li`.
- **PH-SIM SIM-1** — `studio_sim_step_hook` (profile sync + `sim_step` tick stub).
- **PH-SIM SIM-0** — `studio_apply_profile_to_sim` (read-only `SimSessionStub`); `li-sim` path dependency; robotics profile id `4`.

### Changed

- **Breaking:** `studio_profile_sim_robotics()` id `5` → `4` (matches `li_rt_studio_profile_match_name`).

- **Viewport error recovery (UX-08)** — `studio_viewport_error_none`, `studio_err_gpu`, `studio_err_missing_asset`; `StudioViewportErrorOverlay` compose + stroke-only message/retry paint; `studio_viewport_error_retry()` mock via `li_rt_studio_viewport_error_*` (no wgpu failure probe); smoke `studio_viewport_error.li`.
- **Runnable shell demo entry (PH-GD-1)** — `src/main.li` (`studio_shell_demo_frame`, `li-studio-demo` bin), `examples/studio_shell_demo.toml`, smoke `studio_shell_demo.li`; headless compose/paint + keyboard hook per frame (no SDL/wgpu window).
- **Scene outliner (PH-GD-1)** — `StudioOutlinerNode`, `StudioOutlinerCompose`, `studio_compose_outliner`, `studio_paint_outliner`; demo hierarchy (Root, Camera, Mesh) in dock strip below slots; wired into `StudioShellCompose` and shell chrome counts; smoke `studio_outliner.li`.
- **Accessibility (UX-10)** — `studio_paint_focus_ring_for_panel` when `panel.active_region` matches; uses `li-ui` focus ring token.
- **Loading / skeleton (UX-11)** — `StudioShellLoadingState`, `studio_compose_shell_loading`, `studio_paint_shell_loading` (4 fill cmds); smoke `studio_shell_loading.li`.
- **Timeline playback (UX-02)** — `studio_timeline_playing`, `studio_timeline_toggle_play`, `studio_timeline_tick_frame` (+0.01 playhead/frame, cap 1.0); `play_btn_rect` + expanded timeline paint; smoke `studio_timeline_playback.li`.
- **Inspector fields (UX-03)** — `StudioInspectorField` + `studio_compose_inspector_selected` (≥2 label/value rows); empty path uses `studio_compose_empty_inspector`; smoke `studio_inspector_fields.li`.
- **Command palette (UX-04)** — `StudioCommandPaletteCompose` on `StudioShellCompose`; `studio_compose_shell_palette`, `studio_paint_palette_overlay`, `studio_handle_studio_key` / Cmd+K via `li-gui`; smoke `studio_command_palette.li` + `packages/li-ui` `studio_palette.li`.
- **MCP tool contracts (PH-AGENT / AGENT-0)** — `studio_mcp_*` tool IDs, `studio_mcp_tool_name` / `from_name`, `StudioAgentToolRequest`, `docs/game-dev/studio-mcp-tools.md`, smoke `studio_mcp_tools.li`.
- **Runtime profiles (UX-05 / PH-SIM scaffold)** — `studio_profile_*` constants, `studio_profile_from_name`, `studio_parse_toml_profile_line`, `StudioProjectConfig`, topbar profile chip paint, `fixtures/studio.toml`.
- **Empty states (UX-07)** — `studio_compose_empty_inspector`, `studio_compose_empty_viewport`, `studio_empty_state_for_region`; muted placeholder paint with honest inspector/viewport cmd counts; shell wires empty paths when `has_selection == 0` or `scene_entity_count == 0`.
- **Agent chrome gap-close (UX-06)** — `StudioAgentProgress`, `agent_context_label` + `context_rect`, failed `retry_hint_rect` (stroke), `studio_agent_last_action_reversible()` stub; paint cmd counts per state/context.
- **Agent chrome (UX-06)** — `StudioAgentChromeCompose` with task states (idle/running/blocked/failed/done), cancel rect, error strip; `studio_paint_agent` + `studio_compose_shell_agent`.
- **Panel compose** — `StudioDockCompose`, `StudioTimelineCompose`, `StudioInspectorCompose` from `li-ui` shell layout.
- **Paint decomposition** — `studio_paint_dock`, `studio_paint_timeline`, `studio_paint_inspector` (playhead + track + selection header).
- **Shell frame** — `studio_shell_frame` wires compose panels with topbar, viewport grid, and agent strip.
- **Panel switch** — `studio_panel_switch_inspector` / `studio_panel_switch_timeline` on `GuiPanelState`.
