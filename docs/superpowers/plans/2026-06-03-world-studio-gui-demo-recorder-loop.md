---
name: World Studio GUI demo recorder loop
overview: Playwright-style native Studio control (UiSnapshot + MCP ui_*) with optional deterministic video recording (DemoScript replay → frames → MP4). Phase 1 laid foundation; Phase 2 closes end-to-end replay + visual acceptance.
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
  - id: wrec-w8-ui-session
    content: "W8 — UiSession: persistent headless StudioShellCompose bound to MCP session_id (Playwright browser context)"
    status: done
  - id: wrec-w9-real-replay-runner
    content: "W9 — Real replay: JSON load → studio_demo_replay loop → per-step/interpolated frames (fix studio-demo-replay.sh smoke shortcut)"
    status: done
  - id: wrec-w10-trace-and-record
    content: "W10 — Playwright-style trace + record: demo_trace.jsonl alongside MP4; demo_record_* MCP wraps same path as replay"
    status: done
  - id: wrec-w11-visual-acceptance
    content: "W11 — Visual acceptance: frame delta + unique_colors + scenario assertions in completion gate (not duration-only)"
    status: done
  - id: wrec-w12-lic-phase2-merge
    content: "W12 ? Merge lic phase2 (runtime + MCP ui tools) to main; open/merge PR from cursor/world-studio-gui-demo-recorder-phase2"
    status: done
isProject: false
---

# World Studio GUI demo recorder loop

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Pick next pending `wrec-w*`; run progress gate each iteration.

**Goal:** Agents drive the **native Studio shell via a semantic API** (like Playwright on a browser). **Recording a demo MP4** is an optional layer on top of the same API — not pixel-hunting or OBS.

**Architecture (two layers, one engine):**

```text
┌─────────────────────────────────────────────────────────────┐
│  Agent / CI / Cursor MCP                                     │
└───────────────────────────┬─────────────────────────────────┘
                            │
         ┌──────────────────┴──────────────────┐
         │  Control plane (fast, deterministic) │
         │  ui_snapshot → ui_click / ui_key     │
         │  ui_wait → ui_set_value              │
         └──────────────────┬──────────────────┘
                            │ same StudioShellCompose session
         ┌──────────────────┴──────────────────┐
         │  Record plane (optional, for humans) │
         │  capture on step / interpolate motion│
         │  → PNG sequence → ffmpeg → MP4       │
         │  + demo_trace.jsonl (Playwright trace)│
         └───────────────────────────────────────┘
```

1. **UiSnapshot** — accessibility-style element tree (Li-native, not DOM) with stable dot-path IDs.
2. **Control contract** — in-process `studio_ui_*` + MCP `ui_*` on `lis mcp li-engine`.
3. **Recorder** — `DemoScript` JSON replay through the **same** handlers → frames → MP4 + trace.

**Tech stack:** Li (`def` + contracts), `InputState` bridge, `studio_vertical_capture_ppm_auto`, ffmpeg, MCP stdio (`scripts/lis-mcp-li-engine.py`).

**Hub:** [GUI-LIBRARY-PLAN.md](../../GUI-LIBRARY-PLAN.md) · [studio-mcp-tools.md](../../game-dev/studio-mcp-tools.md) · [RECORDING.md](../../demo/RECORDING.md) · [studio-gui-control-rfc.md](../../game-dev/specs/studio-gui-control-rfc.md)

**Agent:** `world_studio_builder`  
**Branch:** `cursor/world-studio-gui-demo-recorder`  
**Sprint goal:** [world-studio-gui-demo-recorder.md](../../../data/goal-directed-sprints/world-studio-gui-demo-recorder.md)

---

## Playwright analogy (canonical mental model)

Yes — you **record demos like Playwright**: drive the UI through a **semantic API**, optionally capture video from the same session. Agents never need pixels to decide the next action.

| Playwright | World Studio | Notes |
|------------|--------------|-------|
| `browser.newContext()` | `ui_session_start` / `demo_record_start` | Persistent `StudioShellCompose` + profile/size |
| `page.goto(url)` | `ui_session_start({ profile, size })` | Headless shell compose, not a URL |
| `page.locator('#id')` | `ui_snapshot` → find `element_id` | Dot-path IDs: `shell.dock.slot.1` |
| `locator.click()` | `ui_click({ element_id })` | Center hit-test → `InputState` → real handlers |
| `page.keyboard.press('Meta+k')` | `ui_key({ key: 'cmd_k' })` | Maps to `studio_handle_studio_key` |
| `page.fill('#input', text)` | `ui_set_value({ element_id, text })` | Demo-safe fields only (v1) |
| `page.waitForTimeout(ms)` | `ui_wait({ ms \| frames })` | Advances motion tweens + demo clock |
| `page.screenshot()` | `capture` step / implicit on record | Native PPM/PNG via Li raster |
| `context.tracing.start()` | `demo_record_start` + trace writer | Append-only `demo_trace.jsonl` |
| `video: 'on'` | `demo_record_finish` → MP4 | ffmpeg H.264 from frame sequence |
| `npx playwright test` | `studio-demo-replay.sh <script.json>` | Deterministic CI replay |
| `npx playwright codegen` | `studio-demo-codegen` (stretch) | MCP trace → `.demo.json` |

**Control loop (agent, no video):**

```text
session = ui_session_start({ profile: "game", size: [1280, 720] })
snap = ui_snapshot({ session_id })
ui_click({ session_id, element_id: "shell.dock.slot.1" })
ui_wait({ session_id, frames: 6 })
snap = ui_snapshot({ session_id })   # assert palette open, etc.
ui_session_stop({ session_id })
```

**Record loop (same API + frames):**

```text
rec = demo_record_start({ script_path: "data/demo-scripts/workspace-tour.demo.json" })
# internally: load JSON → for each step: studio_demo_replay_step → capture/interpolate
demo_record_finish({ session_id, out_mp4: "build/demo-recorder/out/workspace-tour.mp4" })
# emits: MP4 + capture-provenance.json + demo_trace.jsonl
```

Pixels are for **humans and QA**, not for agent decisions.

---

## Phase status

| Phase | Scope | WPs | Status |
|-------|-------|-----|--------|
| **P0** | UiSnapshot + element IDs | W0 | done (foundation) |
| **P1** | In-process UI control | W1 | done (foundation) |
| **P2** | MCP agent surface | W2 | done (foundation) |
| **P3** | DemoScript DSL + replay | W3 | done (in-process; JSON loader pending W9) |
| **P4** | Frame capture pipeline | W4 | done (capture API; wired per-step in W9) |
| **P5** | Video encode + provenance | W5 | done |
| **P6** | Curated demo scenarios | W6 | done (scripts exist; visual proof in W11) |
| **P7** | K8s handoff + manifest | W7 | done |
| **P8** | UiSession (persistent compose) | W8 | **pending** |
| **P9** | Real JSON replay runner | W9 | **pending** |
| **P10** | Trace + record MCP parity | W10 | **pending** |
| **P11** | Visual acceptance gates | W11 | **pending** |

### Known gap (Phase 1 → Phase 2)

Phase 1 delivered Li APIs + smokes + encode scripts, but **`scripts/studio-demo-replay.sh` still uses capture-smoke** (one static PPM × N frames) instead of loading `.demo.json` and calling `studio_demo_replay`. Local MP4s can pass duration gates while showing **no UI interaction**. W9 + W11 close this.

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

### MCP (`lis mcp li-engine`) — tools

**Session (Playwright context):**

| MCP name | Args | Returns |
|----------|------|---------|
| `ui_session_start` | `{profile?, size?: [w,h]}` | `{session_id, snapshot}` |
| `ui_session_stop` | `{session_id}` | `{ok}` |

**Control (Playwright page API):**

| MCP name | Args | Returns |
|----------|------|---------|
| `ui_snapshot` | `{session_id}` | JSON tree + frame metadata |
| `ui_click` | `{session_id, element_id}` | `{ok, snapshot?}` |
| `ui_key` | `{session_id, key}` e.g. `cmd_k`, `escape`, `digit_3` | `{ok, snapshot?}` |
| `ui_set_value` | `{session_id, element_id, text}` | `{ok}` |
| `ui_wait` | `{session_id, ms?, frames?}` | `{ok, snapshot?}` |

**Record (Playwright video + trace):**

| MCP name | Args | Returns |
|----------|------|---------|
| `demo_record_start` | `{script_path}` or `{steps: [...]}` | `{session_id, trace_path}` |
| `demo_record_step` | `{session_id, step}` | `{ok, frame_path?, snapshot?}` |
| `demo_record_finish` | `{session_id, out_mp4, fps?}` | `{mp4, trace, provenance, duration_s}` |

`demo_record_start` **must** call the same `studio_demo_replay_step` path as headless CI — one engine, two entrypoints (MCP vs shell).

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

- Each step advances `StudioShellCompose` through **real handlers** (not paint-only mocks).
- `capture: frame` writes PPM/PNG via `studio_demo_capture_frame` after compose state reflects the step.
- Between steps, **interpolate motion**: for `wait_ms` / `wait_frames`, emit intermediate frames at `fps` so MP4s show panel transitions (Playwright `slowMo` equivalent).
- `demo_trace.jsonl` records `{ts, step, element_id?, key?, snapshot_hash, frame_path?}` per line for debug and future codegen.

---

## Video pipeline (W4–W5, revised in W9)

```text
DemoScript JSON
  → studio_demo_run (Li binary) OR demo_record_* MCP
  → for each step:
       studio_demo_replay_step(compose, step)
       on wait: interpolate N frames (motion tick)
       on capture: studio_demo_capture_frame → frame-####.ppm
  → ffmpeg concat → MP4
  → capture-provenance.json + demo_trace.jsonl
```

**Anti-pattern (Phase 1 only — remove in W9):** capture-smoke once → duplicate frame 300×. Passes duration gate; fails visual gate.

**Scripts:**

| Script | Role |
|--------|------|
| `scripts/studio-demo-replay.sh` | Load JSON → invoke `studio_demo_run` → frame dir (**W9**) |
| `scripts/studio-demo-encode-mp4.sh` | PPM/PNG dir → H.264 30fps |
| `scripts/studio-demo-visual-gate.sh` | unique_colors, frame delta, scenario checks (**W11**) |
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

## P8 — UiSession (W8)

**Problem:** MCP tools need a **persistent compose** across calls (Playwright browser context). Stateless snapshot-only calls cannot drive multi-step flows.

**Deliverables:**

- [ ] `UiSession` type: `{ session_id, compose, profile_id, frame_clock, trace_writer? }`
- [ ] `studio_ui_session_start(profile, w, h) -> session_id`
- [ ] `studio_ui_session_stop(session_id) -> int`
- [ ] MCP `ui_session_start` / `ui_session_stop`; all `ui_*` require `session_id`
- [ ] In-process session table (fixed max sessions for headless CI)

**Smokes:** Two sequential `ui_click` calls on same session change `active_dock` without re-compose.

**Done when:** Cursor agent completes 3-step palette flow in one MCP session without restarting compose.

---

## P9 — Real replay runner (W9)

**Problem:** Shell replay must load `.demo.json` and run `studio_demo_replay`, not capture-smoke duplicate.

**Deliverables:**

- [ ] `studio_demo_script_load_json(path) -> DemoScript` (or host JSON parser → Li struct)
- [ ] `studio_demo_run` binary: `li-tests/smoke/studio_demo_run_from_json.li` → `-o build/demo-recorder/demo_run`
- [ ] Rewrite `scripts/studio-demo-replay.sh`:
  - build/run `demo_run` with script path + frames output dir
  - interpolate frames during `wait_ms` / `wait_frames` at `$FPS`
  - write per-session `capture-provenance.json`
- [ ] Remove capture-smoke duplicate loop from production replay path (keep smoke as unit test only)

**Smokes:**

- `studio/li-tests/smoke/studio_demo_run_workspace_tour.li` — replay JSON; ≥2 captures; unique_colors ≥48 on last frame
- Shell: `studio-demo-replay.sh data/demo-scripts/command-palette.demo.json` produces **different** frames before/after `cmd_k`

**Done when:** All three scenario MP4s show visible UI change (palette open, dock switch, or agent chrome) — not a flat background.

---

## P10 — Trace + record MCP parity (W10)

**Deliverables:**

- [ ] `demo_trace.jsonl` schema + writer hooked to `studio_demo_replay_step`
- [ ] `demo_record_start` loads script and opens trace file
- [ ] `demo_record_finish` runs encode + merges provenance
- [ ] MCP smoke: start → one step → finish produces MP4 + trace with ≥3 lines

**Stretch:** `scripts/studio-demo-codegen.sh` — trace → draft `.demo.json` (Playwright codegen).

**Done when:** Live MCP recording and headless shell replay produce **byte-identical frame sequences** given same script + seed.

---

## P11 — Visual acceptance (W11)

**Problem:** Completion gate currently checks **duration only** — static 10s videos pass.

**Deliverables:**

- [ ] `scripts/studio-demo-visual-gate.sh`:
  - `unique_colors ≥ 48` on capture frames (not 3)
  - frame hash delta: ≥1 pair differs between first and post-`cmd_k` frame in palette scenario
  - optional: `ui_snapshot` element count ≥ 20 after compose
- [ ] Wire into `world-studio-gui-demo-recorder-completion-gate.sh`
- [ ] Document failure modes in iteration assessment template

**Done when:** Intentionally broken smoke replay (static duplicate) **fails** completion gate; fixed W9 replay **passes**.

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

## Out of scope (v1)

- Live desktop screen recording (OBS) — deterministic API replay only
- wgpu readback for 3D viewport animation (chrome capture v1; viewport grid honesty)
- Cloud upload to YouTube API (manual or Release asset sufficient)
- Full 7-vertical tour MP4 (stretch after W11)
- **HTTP control sidecar** for non-Cursor agents (defer post-W10; MCP stdio is v1 transport)
- Vision/OCR agents driving UI — use `ui_snapshot` IDs instead

## Out of scope (v2+)

- `studio-demo-codegen` from trace (listed as W10 stretch)
- Multi-window / detached viewport sessions
- Remote WebSocket control (`ws://studio/ui`) for non-MCP automation

---

## Iteration checklist

1. Checkout `cursor/world-studio-gui-demo-recorder` (studio + lic)
2. Next pending `wrec-w*` (Phase 2: W8 → W11)
3. Run progress gate
4. Replay one scenario via **real JSON runner**; run visual gate; encode MP4
5. Update manifest + YAML todo
6. Push; K8s worker continues if deployed
