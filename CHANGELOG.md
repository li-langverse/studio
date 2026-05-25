# Changelog

## [Unreleased]

Synced from lic @ `3ece8c173388c9783a18fabf9403cec2fb60dced`.

### Added

- **PH-GD-1 scene outliner** — `StudioOutlinerCompose`, dock-strip rows, `studio_outliner.li` smoke; `li_std_studio_version` → 5.
- **Timeline / inspector smokes** — `studio_timeline_playback.li`, `studio_inspector_fields.li` in manifest.
- **Shell loading & demo (UX-10/11, PH-GD-1)** — `studio_shell_loading.li`, `studio_shell_demo.li` in manifest.
- **MCP tools smoke (disk-only)** — `studio_mcp_tools.li` until lic lands `studio_mcp_*` APIs in `src/lib.li`.

### Changed

- **Manifest** — aligned with lic `packages/li-studio/li-tests/manifest.toml` (11 smokes; `studio_mcp_tools.li` off-manifest).
- **src/lib.li** — outliner paint/compose, timeline playhead, empty states, agent chrome from lic HEAD.
