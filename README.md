# li-studio

Li World Studio product shell: composes **dock**, **timeline**, and **inspector** panels from `li-ui` layout IR and `li-gui` paint primitives.

Import: `import studio`

## Compose API

- `studio_compose_shell` — layout + dock/timeline/inspector structs + panel state
- `studio_paint_compose_panels` — paint dock slots, timeline track/playhead, inspector chrome
- `studio_shell_frame` — full editor chrome (panels + topbar + viewport grid + agent chrome)
- `studio_compose_agent_chrome` / `studio_paint_agent` — task status, cancel button, error strip (UX-06)
- `studio_panel_switch_inspector` / `studio_panel_switch_timeline` — PH-UX panel switch hooks
