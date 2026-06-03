---
name: World Studio GUI demo recorder loop
overview: Goal-directed sprint — agent-controllable native Studio UI (MCP + in-process contract), scripted demo replay, frame capture, and ffmpeg MP4 delivery. Replaces HTML mock reels for product truth demos.
todos:
  - id: wrec-w0-ui-snapshot-tree
    content: "W0 — UiSnapshot tree: stable element IDs, bounds, roles, accessibility labels on shell widget tree"
    status: done
  - id: wrec-w1-control-dispatch
    content: "W1 — Control dispatch: ui_click/ui_key/ui_set_value via InputState + hit-test (in-process API)"
    status: done
  - id: wrec-w2-mcp-ui-tools
    content: "W2 — MCP ui_* tools on lis mcp li-engine (snapshot, click, key, wait, set_value)"
    status: done
  - id: wrec-w3-demo-script-dsl
    content: "W3 — DemoScript DSL (JSON) + studio_demo_replay_step with requires/ensures"
    status: done
  - id: wrec-w4-frame-capture
    content: "W4 — Per-step native frame capture (PPM/PNG) after compose+paint; honest native_pixels flag"
    status: done
  - id: wrec-w5-video-encode
    content: "W5 — ffmpeg MP4 encoder + capture-provenance.json (no large binaries in git)"
    status: done
  - id: wrec-w6-scenario-library
    content: "W6 — Three curated scenarios (workspace tour, palette flow, agent invoke) + acceptance MP4s"
    status: done
  - id: wrec-w7-k8s-recorder-agent
    content: "W7 — Recorder worker docs, gates, delivery manifest; completion gate passes"
    status: done
isProject: false
---

# World Studio GUI demo recorder loop

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Pick next pending `wrec-w*`; run progress gate each iteration.

**Goal:** Agents (and you) can **drive the native Studio shell** and **deliver MP4 demo videos** — not HTML mock slideshows.

**Architecture:** Three layers:

1. **UiSnapshot** — serializable element tree (Li-native, not browser DOM) with stable IDs.
2. **Control contract** — in-process `studio_ui_*` dispatch + MCP `ui_*` tools on `lis mcp li-engine`.
3. **Recorder** — `DemoScript` replay → per-step PNG frames → ffmpeg → MP4 + provenance manifest.

**Tech stack:** Li (`def` + contracts), existing `InputState` bridge, `studio_vertical_capture_ppm_auto`, ffmpeg, MCP stdio (`scripts/lis-mcp-li-engine.py`).

**Hub:** [GUI-LIBRARY-PLAN.md](../../GUI-LIBRARY-PLAN.md) · [studio-mcp-tools.md](../../game-dev/studio-mcp-tools.md) · [RECORDING.md](../../demo/RECORDING.md)

**Agent:** `world_studio_builder`  
**Branch:** `cursor/world-studio-gui-demo-recorder`  
**Sprint goal:** [world-studio-gui-demo-recorder.md](../../../data/goal-directed-sprints/world-studio-gui-demo-recorder.md)

---

## Phase status

| Phase | Scope | WPs | Status |
|-------|-------|-----|--------|
| **P0** | UiSnapshot + element IDs | W0 | pending |
| **P1** | In-process UI control | W1 | pending |
| **P2** | MCP agent surface | W2 | pending |
| **P3** | DemoScript DSL + replay | W3 | pending |
| **P4** | Frame capture pipeline | W4 | pending |
| **P5** | Video encode + provenance | W5 | pending |
| **P6** | Curated demo scenarios | W6 | pending |
| **P7** | Acceptance + K8s handoff | W7 | pending |

---

## Gates

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
./scripts/world-studio-gui-demo-recorder-gates.sh
./scripts/world-studio-gui-demo-recorder-completion-gate.sh   # sprint done
```

---

## Why not browser MCP alone?

| Approach | Problem |
|----------|---------|
| **cursor-ide-browser** on HTML mocks | Not native pixels; contradicts product-visual / typography-fx truth |
| **Playwright on deploy/studio-demo** | Marketing mock only; cannot drive wgpu viewport or sim state |
| **Li-native control + capture** | Same binary agents ship; deterministic replay; MCP + headless CI |

Browser MCP remains useful for **docs site** only — out of scope for this sprint.

---

## Control contract (target API)

### In-process (`import studio`)

| Symbol | Role |
|--------|------|
| `studio_ui_snapshot(compose) -> UiSnapshot` | Full tree JSON-serializable struct |
| `studio_ui_element_find(snap, id) -> UiElementRef` | Lookup by stable ID |
| `studio_ui_click(compose, id) -> int` | Hit-test center of element; pointer_down/up |
| `studio_ui_key(compose, key_action) -> int` | Maps to `InputState` + `studio_handle_studio_key` |
| `studio_ui_set_value(compose, id, text) -> int` | Text inputs / inspector fields (where wired) |
| `studio_ui_wait_frames(compose, n) -> unit` | Advance demo clock / motion tweens |
| `studio_demo_replay(script, compose) -> DemoReplayResult` | Run full script |

### MCP (`lis mcp li-engine`) — new tools

| MCP name | Args | Returns |
|----------|------|---------|
| `ui_snapshot` | `{profile?: str, size?: [w,h]}` | JSON tree + frame metadata |
| `ui_click` | `{element_id: str}` | `{ok, new_snapshot?}` |
| `ui_key` | `{key: str}` e.g. `cmd_k`, `escape`, `digit_3` | `{ok}` |
| `ui_set_value` | `{element_id, text}` | `{ok}` |
| `ui_wait` | `{ms?: int, frames?: int}` | `{ok}` |
| `demo_record_start` | `{script_path or inline steps}` | `{session_id}` |
| `demo_record_step` | `{session_id, step}` | `{frame_path?}` |
| `demo_record_finish` | `{session_id, out_mp4}` | `{mp4, provenance, duration_s}` |

Register in `studio_mcp_tool_*` (+ bump `studio_mcp_tool_count()`); extend `scripts/lis-mcp-li-engine.py` allowlist.

---

## UiSnapshot element ID scheme

Stable dot-path IDs (never positional indices alone):

```
shell.topbar.profile_chip
shell.dock.slot.2
shell.outliner.row.root
shell.inspector.field.selection_name
shell.viewport.menu.tier_chip
shell.timeline.play_button
shell.agent.send_button
shell.palette.search
shell.palette.row.0
```

**Struct sketch** (`lic/packages/li-gui/src/ui_snapshot.li`):

```text
UiElement = object
  id: str
  role: int          # button | label | panel | input | ...
  bounds: Rect
  label: str         # truncated display text
  enabled: int
  focused: int
  child_count: int

UiSnapshot = object
  frame_id: int
  profile_id: int
  width: int
  height: int
  element_count: int
  root: UiElement    # flat or region-indexed; smokes assert count
```

Build from `ShellWidgetTree` + `WidgetNode` layout results + compose rects (inspector, palette, agent).

---

## DemoScript DSL (W3)

File: `data/demo-scripts/<scenario>.demo.json`

```json
{
  "name": "workspace-tour",
  "profile": "game",
  "size": [1280, 720],
  "fps": 30,
  "hold_ms_default": 800,
  "native_only": true,
  "steps": [
    {"wait_ms": 500},
    {"ui_key": "digit_1"},
    {"wait_ms": 400},
    {"ui_click": "shell.dock.slot.1"},
    {"wait_frames": 6},
    {"ui_key": "cmd_k"},
    {"wait_ms": 300},
    {"capture": "frame"},
    {"ui_click": "shell.palette.row.0"},
    {"wait_ms": 600},
    {"capture": "frame"}
  ]
}
```

Replay rules:

- Each step advances `StudioShellCompose` through real handlers (not paint-only mocks).
- `capture: frame` writes PNG via `studio_vertical_capture_ppm_auto` → ppm2png.
- Motion steps use `studio_motion_tick` from typography-fx sprint.

---

## Video pipeline (W4–W5)

```text
DemoScript → replay loop → PNG sequence (build/demo-recorder/<session>/frame-%04d.png)
          → ffmpeg concat demuxer → MP4
          → capture-provenance.json (studio_sha, lic_sha, native_pixels, script_hash)
```

**Scripts:**

| Script | Role |
|--------|------|
| `scripts/studio-demo-replay.sh` | Headless replay one script |
| `scripts/studio-demo-encode-mp4.sh` | PNG dir → H.264 30fps |
| `scripts/world-studio-gui-demo-recorder-gates.sh` | Progress gate |

**Delivery to you (Julian):**

- MP4s uploaded to GitHub Release asset or artifact URL recorded in `data/world-studio-gui-demo-recorder-loop/latest-videos.json`
- **Do not commit MP4 to git** (follow `record-studio-demo` skill policy)
- Local path after agent run: `build/demo-recorder/out/<scenario>.mp4`

---

## P0 — UiSnapshot tree (W0)

**Files:**

- `lic/packages/li-gui/src/ui_snapshot.li` (mirrored to `lib.li`)
- `studio/src/lib.li` — `studio_ui_snapshot_from_compose`
- `studio/docs/game-dev/specs/studio-gui-control-rfc.md` (RFC stub)

**Smokes:**

- `li-gui/li-tests/smoke/ui_snapshot_shell_regions.li` — ≥8 regions, IDs stable across two frames with same compose
- `studio/li-tests/smoke/studio_ui_snapshot.li` — game profile snapshot, `shell.topbar.profile_chip` exists

**Done when:** Snapshot JSON schema documented; element_count ≥ 20 on full shell.

---

## P1 — Control dispatch (W1)

**Deliverables:**

- [ ] `studio_ui_click` resolves ID → `Rect` → synthetic `InputState` at center
- [ ] Reuse `studio_shell_handle_*_pointer`, `studio_handle_studio_key`
- [ ] `studio_ui_wait_frames` calls `studio_motion_tick` + demo frame advance
- [ ] Smokes: click dock slot changes `active_dock`; cmd_k opens palette

**Done when:** Replay of 3-step script passes without MCP (in-process only).

---

## P2 — MCP ui_* tools (W2)

**Files:**

- `lic/packages/li-studio/src/lib.li` — new `studio_mcp_ui_*` tool IDs
- `scripts/lis-mcp-li-engine.py` — allowlist + JSON arg parsing
- `studio/docs/game-dev/studio-mcp-tools.md` — tool table update

**Smokes:**

- `studio/li-tests/smoke/studio_mcp_ui_snapshot.li`
- `studio/li-tests/smoke/studio_mcp_ui_click.li`
- `scripts/studio-mcp-li-engine-smoke.sh` — tools/list includes `ui_snapshot`

**Done when:** Cursor agent can call `ui_snapshot` + `ui_click` via stdio MCP against headless studio session.

---

## P3 — DemoScript DSL (W3)

**Deliverables:**

- [ ] `DemoScript`, `DemoScriptStep` types in `studio/src/demo_recorder.li`
- [ ] `studio_demo_script_load(path) -> DemoScript`
- [ ] `studio_demo_replay_step(compose, step) -> DemoStepResult`
- [ ] Schema: `data/demo-scripts/schema.demo.json`

**Smokes:** `studio/li-tests/smoke/studio_demo_replay_minimal.li` (wait + capture only)

---

## P4 — Frame capture (W4)

**Deliverables:**

- [ ] `studio_demo_capture_frame(compose, path, w, h) -> int` wraps `studio_vertical_capture_ppm_auto`
- [ ] PNG writer or ppm→png step in `scripts/studio-demo-replay.sh`
- [ ] Provenance field `native_pixels: true` when Li raster path used

**Smokes:** `studio/li-tests/smoke/studio_demo_capture_frame.li` — PNG ≥12KB, unique colors ≥48

---

## P5 — Video encode (W5)

**Deliverables:**

- [ ] `scripts/studio-demo-encode-mp4.sh` — ffmpeg H.264 yuv420p 30fps
- [ ] `capture-provenance.json` template alongside MP4
- [ ] Gate verifies ffprobe duration within ±10% of script estimate

**Done when:** Minimal 3-frame script produces playable MP4 locally.

---

## P6 — Scenario library (W6)

**Curated scripts** (`data/demo-scripts/`):

| Scenario | Story | Target duration |
|----------|-------|-----------------|
| `workspace-tour.demo.json` | Region focus digits 1–5, dock, outliner | ~25s |
| `command-palette.demo.json` | cmd_k → search → pick action | ~15s |
| `agent-invoke.demo.json` | Agent send → running → done progress | ~20s |

**Acceptance outputs** (manifest paths, not necessarily in git):

- `build/demo-recorder/out/workspace-tour.mp4`
- `build/demo-recorder/out/command-palette.mp4`
- `build/demo-recorder/out/agent-invoke.mp4`

**Optional:** Vertical variant `game-verticals-tour.demo.json` (profile switches) — stretch goal.

---

## P7 — Acceptance (W7)

**Deliverables:**

- [ ] `data/world-studio-gui-demo-recorder-loop/latest-videos.json` — URLs or local paths + provenance hashes
- [ ] `latest-iteration-assessment.json`
- [ ] Completion gate: all `wrec-w*` done; 3 MP4s exist; ffprobe duration > 10s each
- [ ] K8s worker bundle applied (see sprint goal)

**Human delivery:** Post MP4 links in iteration assessment or GitHub Release; user downloads for X/LinkedIn.

---

## File map

| Area | Path |
|------|------|
| RFC | `studio/docs/game-dev/specs/studio-gui-control-rfc.md` |
| Snapshot | `lic/packages/li-gui/src/ui_snapshot.li` |
| Control | `studio/src/demo_recorder.li`, `studio/src/lib.li` |
| MCP | `lic/packages/li-studio/src/lib.li`, `scripts/lis-mcp-li-engine.py` |
| Scripts | `studio/scripts/studio-demo-replay.sh`, `studio-demo-encode-mp4.sh` |
| Gates | `studio/scripts/world-studio-gui-demo-recorder-*.sh` |
| Scenarios | `studio/data/demo-scripts/*.demo.json` |
| Manifest | `studio/data/world-studio-gui-demo-recorder-loop/` |

---

## K8s handoff

```powershell
cd li-cursor-agents
.\scripts\deploy-world-studio-gui-demo-recorder-k8s.ps1 -KubeConfig "$env:USERPROFILE\.kube\config"
```

Worker: `li-world-studio-gui-demo-recorder` · Agent: `world_studio_builder` · Branch: `cursor/world-studio-gui-demo-recorder`

**Note:** Video encoding requires **ffmpeg in worker image** or sidecar init; document in deployment if missing.

---

## Out of scope

- Live desktop screen recording (OBS) — we ship **deterministic replay** only
- wgpu readback for 3D viewport animation (use existing CPU chrome capture; viewport grid honesty)
- Cloud upload to YouTube API (manual or Release asset sufficient for v1)
- Full 7-vertical tour MP4 (separate stretch after W6)

---

## Iteration checklist

1. Checkout `cursor/world-studio-gui-demo-recorder` (studio + lic)
2. Next pending `wrec-w*`
3. Run progress gate
4. Replay one scenario; encode MP4
5. Update manifest + YAML todo
6. Push; K8s worker continues
