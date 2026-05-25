# li-studio

Li World Studio product shell: composes **dock**, **timeline**, and **inspector** panels from `li-ui` layout IR and `li-gui` paint primitives.

Import: `import studio`

## Syntax

Use **`def`** for functions; do not add bare **`proc`**. **`extern proc`** only for FFI. See `lic/docs/game-dev/world-studio-vision.md` and `.cursor/rules/li-def-not-proc.mdc`.

## Compose API

- `studio_compose_shell` / `studio_compose_shell_profile` — layout + `StudioProjectConfig.active_profile`
- `studio_profile_from_name` / `studio_parse_toml_profile_line` — PH-SIM profile stub (`fixtures/studio.toml`)
- `studio_paint_topbar_profile` — topbar chip; `last_rect.h` encodes active profile id
- `studio_paint_compose_panels` — paint dock slots, timeline track/playhead, inspector chrome
- `studio_shell_frame` — full editor chrome (panels + topbar + viewport grid + agent chrome)
- `studio_compose_agent_chrome` / `studio_paint_agent` — task status, step progress, context label, cancel, error strip, retry hint (UX-06)
- `studio_compose_empty_inspector` / `studio_compose_empty_viewport` — UX-07 empty-state placeholders
- `studio_timeline_playback_*` / `studio_inspector_field_*` — UX-02/03 timeline scrub + inspector field rows
- `studio_panel_switch_inspector` / `studio_panel_switch_timeline` — PH-UX panel switch hooks

## Agent chrome (UX-06)

| Field / API | Purpose |
|-------------|---------|
| `StudioAgentProgress` | Determinate progress bar when `task_state == running` |
| `agent_context_label` | Context id; `studio_agent_context_world()` / `selection()` label rects |
| `retry_hint_rect` | Failed-state retry affordance (stroke) |
| `studio_agent_last_action_reversible()` | Undo contract stub until host wires undo |

## X demo (marketing reel)

Reproducible ~37s Studio UI reel for social posts: `docs/demo/studio-x-demo-script.md`, `docs/demo/media/studio-x-demo.mp4`, `./scripts/record-studio-x-demo.sh`. Capture strategy and stack map: `docs/demo/RECORDING.md` (HTML mocks from `lic` `deploy/studio-demo`).
