# Changelog

## [Unreleased]

Synced from lic @ `0aed1aa548e8bac48ec1267e541fc9a8d03874f9`.

### Added

- **`li-studio-demo` binary** — `[[bin]]` in `li.toml`, `src/main.li`, `examples/studio_shell_demo.toml`.
- **UX-08 viewport error** — `studio_viewport_error.li` smoke; manifest entry.
- **MCP tool contracts (PH-AGENT)** — `studio_mcp_*` APIs in `src/lib.li`; `studio_mcp_tools.li` in manifest.

### Changed

- **Manifest** — 12 smokes parity with lic `packages/li-studio/li-tests/manifest.toml` (timeline, inspector, outliner, shell demo/loading, MCP).
- **src/lib.li** — PH-GD-1 headless shell demo frame contract, profile roundtrip, viewport error surface from lic `feat/studio-gap-close-wave1` HEAD.
