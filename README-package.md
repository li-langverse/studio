# li-studio

Li World Studio product shell: composes **dock**, **timeline**, and **inspector** panels from `li-ui` layout IR and `li-gui` paint primitives.

Import: `import studio`

## Run demo (PH-GD-1 / PH-HW WP3)

**`li-studio-demo`** runs `studio_shell_demo_present_loop`: cycles `studio_vertical_demo_frame` / `studio_shell_demo_frame` per tick with `STUDIO_DEMO_PROFILE`, host `InputState` (`studio_shell_input_from_host` → `studio_handle_studio_key`), and optional `LIG_HOST_PRESENT` blit/present via `studio_shell_host_present_loop_tick`. Compose/paint IR is real; full wgpu viewport swapchain may still be partial — use the existing host-present path first.

```bash
# Headless contract (default 3 ticks, game profile)
cd packages/li-studio
lic check src/main.li
lic build --allow-open-vc --no-lean-verify src/main.li -o build/li-studio-demo
./build/li-studio-demo

# Interactive SDL/mock loop (one frame per tick; pattern 0→1→2 via STUDIO_DEMO_LOOP_TICK)
./scripts/studio-shell-demo-interactive.sh
# STUDIO_INTERACTIVE_MAX_TICKS=9 ./scripts/studio-shell-demo-interactive.sh

# Vertical + host present (CI-safe mock input; optional SDL present host)
cd ../..   # lic repo root
STUDIO_DEMO_PROFILE=sim_drug_design STUDIO_DEMO_FRAMES=3 \
  LIG_HOST_PRESENT=1 ./scripts/studio-shell-demo-present-loop.sh

# Build and run demo binary with mock keys + present tick
STUDIO_SHELL_DEMO_BUILD_RUN=1 LIG_HOST_PRESENT=1 \
  STUDIO_DEMO_PROFILE=game ./scripts/studio-shell-demo-present-loop.sh
```

| Env | Role |
|-----|------|
| `STUDIO_DEMO_PROFILE` | Profile slug or id (`game`, `sim_rl`, `sim_drug_design`, …) |
| `STUDIO_DEMO_FRAMES` | Frames per `li-studio-demo` invocation (1–64; default 3; interactive default 1) |
| `STUDIO_DEMO_LOOP_TICK` | Base pattern index for present loop (mod 3); interactive script sets each tick |
| `STUDIO_DEMO_LOOP_AUTO=1` | In-process tick counter when `STUDIO_DEMO_LOOP_TICK` unset (optional) |
| `LIG_HOST_PRESENT=1` | Enable `lig_present_blit_paint_summary` + `studio_shell_host_present_loop_tick` |
| `STUDIO_SHELL_INPUT_MOCK` | Keys for `studio_shell_input_from_host` (e.g. `cmd_k,digit=3`) |
| `STUDIO_SHELL_PRESENT_HOST_BIN` | SDL one-shot present host (`deploy/studio-demo/native/studio_shell_present_host`) |

Dimensions: `examples/studio_shell_demo.toml` (1280×720). Smokes: `studio_shell_demo.li`, `studio_shell_demo_present_loop.li`, `studio_host_present.li`.

## Compose API

- `studio_compose_shell` / `studio_compose_shell_profile` — layout + `StudioProjectConfig.active_profile`
- `studio_profile_from_name` / `studio_parse_toml_profile_line` — PH-SIM profile stub (`fixtures/studio.toml`)
- `studio_toml_parse_line` / `studio_toml_parsed_config` — WP-SIM-06 `[engine]` determinism + `[engine.export]` (`examples/verticals/sim_additive/studio.toml`)
- `studio_paint_topbar_profile` — topbar chip; `last_rect.h` encodes active profile id
- `studio_compose_outliner` / `studio_paint_outliner` — scene hierarchy stub (Root, Camera, Mesh) in dock strip below slots (PH-GD-1)
- `studio_paint_compose_panels` — paint dock slots, outliner rows, timeline track/playhead, inspector chrome
- `studio_shell_frame` — full editor chrome (panels + topbar + viewport grid + agent chrome)
- **PH-UX viewport display** — `StudioViewportDisplayCompose` + `StudioViewportMenuCompose` on shell; background preset (solid/grid/gradient), MD particle tier dots (placeholder), biomol style chip; MCP `studio_set_viewport_background`, `studio_set_particle_display`, `studio_set_biomol_style` (`studio_mcp_tool_dispatch_arg`); defaults for `sim_scientific` / `sim_drug_design`; smoke `studio_viewport_display.li`
- **UX-08** — `studio_err_gpu` / `studio_err_missing_asset`, `StudioViewportErrorOverlay`, `studio_viewport_error_retry()` (mock; native wgpu probe not wired)
- `studio_compose_agent_chrome` / `studio_paint_agent` — task status, step progress, context label, cancel, error strip, retry hint (UX-06)
- `StudioAgentRun` / `studio_agent_run_*` — in-process PH-AGENT state for the world-patch → `lic_check` → `lic_build` tool sequence; `used_html_mock == 0` is part of the run contract
- `studio_panel_switch_inspector` / `studio_panel_switch_timeline` — PH-UX panel switch hooks
- `studio_compose_shell_loading` / `studio_paint_shell_loading` — UX-11 skeleton rects (viewport + inspector fields); no spinner paint IR
- `studio_paint_focus_ring_for_panel` — UX-10 focus stroke when `panel.active_region` matches (see `li-ui` `studio_paint_focus_ring`)

## Loading / skeleton (UX-11)

| Field / API | Purpose |
|-------------|---------|
| `StudioShellLoadingState` | `shell_loading`, `viewport_skeleton`, `inspector_*_skeleton` rects on compose |
| `studio_compose_shell_loading(..., shell_loading)` | Sets skeleton rects when `studio_shell_loading_on()` |
| `studio_paint_shell_loading` | Four muted `paint_op_fill_rect` cmds (honest placeholder, not a spinner) |
| `studio_shell_loading_frame` | Chrome + skeleton paint for smoke / host bootstrap |

## Accessibility (UX-10)

- `studio_paint_focus_ring_for_panel` paints one stroke around `studio_region_rect_for_focus` when the active region is not the default viewport.
- Contrast: `studio_contrast_ratio_ok()` lives in `li-ui` (stub `1.0`; WCAG AA **4.5:1** target documented there).
- **Follow-up:** axe in CI when `world-studio-demo` ux-harness exists — not wired in package smoke yet.

## Agent chrome (UX-06)

| Field / API | Purpose |
|-------------|---------|
| `StudioAgentProgress` | `step_index`, `step_total`, `progress_rect`; `visible == 1` only when `task_state == running` (determinate bar, not a spinner) |
| `agent_context_label` | Context id on compose; painted as `context_rect` stroke inside status |
| `studio_agent_context_world()` | Label id `1` → display **world.li** |
| `studio_agent_context_selection()` | Label id `2` → display **selection: Node** |
| `retry_hint_rect` | Failed-state retry affordance (stroke only) |
| `studio_agent_last_action_reversible()` | Undo contract stub; returns `0` until host wires undo |
| `StudioAgentRun` | In-process agent run record; tracks active tool, progress, patch/check/build flags, and `used_html_mock == 0` |
| `studio_agent_tool_request_for_run` | Converts a `StudioAgentRun` into the existing chrome tool trace request |

Failures use `studio_color_agent_error()` on status + error strip; running state never masks failed tasks.
