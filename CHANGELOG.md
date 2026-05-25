# Changelog

## [Unreleased]

Synced from lic `feat/studio-gap-close-wave1` @ `c562826a`.

### Added

- **Timeline / inspector smokes** — `studio_timeline_playback.li`, `studio_inspector_fields.li` (manifest); `studio_mcp_tools.li` on disk only until lic lands MCP APIs.
- **Runtime profiles (UX-05 / PH-SIM scaffold)** — `studio_profile_*`, `studio_profile_from_name`, `studio_parse_toml_profile_line`, `StudioProjectConfig`, topbar profile chip; `fixtures/studio.toml`.
- **Empty states (UX-07)** — `studio_compose_empty_inspector`, `studio_compose_empty_viewport`, `studio_empty_state_for_region`; shell empty paths when no selection or empty scene.
- **Agent chrome gap-close (UX-06)** — `StudioAgentProgress`, `agent_context_label`, `retry_hint_rect`, `studio_agent_last_action_reversible()` stub.
- **Command palette smokes** — `studio_command_palette.li`, `studio_empty_states.li`, `studio_profile_roundtrip.li` in `li-tests/manifest.toml`.

### Changed

- **Docs:** Agent rule `li-def-not-proc.mdc`; README syntax line — teach **`def`** only (see `lic` `docs/release-notes/2026-05-25-studio-def-not-proc-docs.md`).

### Added

- **Studio X demo** — `docs/demo/studio-x-demo-script.md`, `docs/demo/RECORDING.md`, `docs/demo/media/studio-x-demo.mp4`, `scripts/record-studio-x-demo.sh` (HTML mocks from `lic` `deploy/studio-demo`).
- **Agent chrome (UX-06)** — `StudioAgentChromeCompose` with task states (idle/running/blocked/failed/done), cancel rect, error strip; `studio_paint_agent` + `studio_compose_shell_agent`.
- **Panel compose** — `StudioDockCompose`, `StudioTimelineCompose`, `StudioInspectorCompose` from `li-ui` shell layout.
- **Paint decomposition** — `studio_paint_dock`, `studio_paint_timeline`, `studio_paint_inspector` (playhead + track + selection header).
- **Shell frame** — `studio_shell_frame` wires compose panels with topbar, viewport grid, and agent strip.
- **Panel switch** — `studio_panel_switch_inspector` / `studio_panel_switch_timeline` on `GuiPanelState`.
