# RFC: Studio GUI control + demo recorder

**Status:** Draft (Phase 2 in progress)  
**Date:** 2026-06-03 (updated 2026-06-04)  
**Plan:** [2026-06-03-world-studio-gui-demo-recorder-loop.md](../superpowers/plans/2026-06-03-world-studio-gui-demo-recorder-loop.md)

## Problem

Agents and CI need to **drive native Studio UI** and produce **demo videos** without HTML mocks or manual screen recording. Pixel-based control (screenshots + vision) is slow and brittle. Today MCP covers project/sim/viewport presets only — not per-element control.

## Proposal (Playwright-style)

Two layers, one engine:

1. **Control plane** — fast semantic API for agents (like Playwright locators + actions).
2. **Record plane** — optional MP4 + trace from the **same** step runner (like Playwright `video` + `tracing`).

### Control plane

- **UiSnapshot** — serializable element tree with stable dot-path IDs (`shell.dock.slot.1`).
- **UiSession** — persistent `StudioShellCompose` bound to `session_id` (Playwright browser context).
- **In-process** `studio_ui_*` dispatch via existing `InputState` bridge.
- **MCP** `ui_session_*`, `ui_*` on `lis mcp li-engine`.

### Record plane

- **DemoScript** JSON — declarative step list (Playwright test script).
- **Replay** — `studio_demo_replay_step` for each step; interpolate frames on waits.
- **Output** — PNG sequence → ffmpeg MP4 + `demo_trace.jsonl` + `capture-provenance.json`.

Agents use **snapshots + element IDs** to decide actions. Video is for humans and CI visual proof, not for the control loop.

## Li syntax

Use **`def`** for all new APIs. **`extern proc`** only for FFI. Contracts on every export.

## Security

- MCP allowlist only; no shell passthrough.
- `ui_set_value` limited to demo-safe fields (inspector stubs, palette search).
- Replay scripts ship from repo `data/demo-scripts/` — no arbitrary JSON from network in v1.
- Session table capped (fixed max concurrent headless sessions).

## Phase 1 vs Phase 2

| Item | Phase 1 (W0–W7) | Phase 2 (W8–W11) |
|------|-----------------|------------------|
| UiSnapshot + ui_click/key | In-process smokes | MCP session-bound |
| DemoScript types + replay_step | Li API | JSON loader + shell runner |
| MP4 pipeline | encode + duration gate | real replay + visual gate |
| Trace | — | demo_trace.jsonl |

**Known gap:** `studio-demo-replay.sh` currently duplicates capture-smoke frames; W9 replaces this with real JSON replay.

## Open questions

- [ ] HTTP / WebSocket sidecar for non-Cursor agents (defer post-W10)
- [ ] wgpu viewport frame in MP4 (stretch; chrome-only v1)
- [ ] Codegen: MCP trace → `.demo.json` (W10 stretch)
