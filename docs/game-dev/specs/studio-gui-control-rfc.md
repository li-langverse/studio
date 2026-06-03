# RFC: Studio GUI control + demo recorder

**Status:** Draft  
**Date:** 2026-06-03  
**Plan:** [2026-06-03-world-studio-gui-demo-recorder-loop.md](../superpowers/plans/2026-06-03-world-studio-gui-demo-recorder-loop.md)

## Problem

Agents and CI need to **drive native Studio UI** and produce **demo videos** without HTML mocks or manual screen recording. Today MCP covers project/sim/viewport presets only — not per-element control.

## Proposal

1. **UiSnapshot** — serializable element tree with stable dot-path IDs.
2. **In-process** `studio_ui_*` control dispatch via existing `InputState` bridge.
3. **MCP** `ui_*` + `demo_record_*` tools on `lis mcp li-engine`.
4. **DemoScript** JSON replay → PNG frames → ffmpeg MP4.

## Li syntax

Use **`def`** for all new APIs. **`extern proc`** only for FFI. Contracts on every export.

## Security

- MCP allowlist only; no shell passthrough.
- `ui_set_value` limited to demo-safe fields (inspector stubs, palette search).
- Replay scripts ship from repo `data/demo-scripts/` — no arbitrary JSON from network in v1.

## Open questions

- [ ] HTTP control sidecar for non-Cursor agents (defer post-W2)
- [ ] wgpu viewport frame in MP4 (stretch; chrome-only v1)
