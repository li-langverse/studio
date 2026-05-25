# Changelog

## [Unreleased]

### Changed

- **Docs:** Agent rule `li-def-not-proc.mdc`; README syntax line — teach **`def`** only (see `lic` `docs/release-notes/2026-05-25-studio-def-not-proc-docs.md`).

### Added

- **Studio X demo** — `docs/demo/studio-x-demo-script.md`, `docs/demo/RECORDING.md`, `docs/demo/media/studio-x-demo.mp4`, `scripts/record-studio-x-demo.sh` (HTML mocks from `lic` `deploy/studio-demo`).
- **Agent chrome (UX-06)** — `StudioAgentChromeCompose` with task states (idle/running/blocked/failed/done), cancel rect, error strip; `studio_paint_agent` + `studio_compose_shell_agent`.
- **Panel compose** — `StudioDockCompose`, `StudioTimelineCompose`, `StudioInspectorCompose` from `li-ui` shell layout.
- **Paint decomposition** — `studio_paint_dock`, `studio_paint_timeline`, `studio_paint_inspector` (playhead + track + selection header).
- **Shell frame** — `studio_shell_frame` wires compose panels with topbar, viewport grid, and agent strip.
- **Panel switch** — `studio_panel_switch_inspector` / `studio_panel_switch_timeline` on `GuiPanelState`.
