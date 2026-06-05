---
workflow_repo: studio
---

# Sprint: World Studio GUI demo recorder — Playwright-style control + native MP4

**Repo:** `studio` (+ `lic`: `li-gui`, `li-studio`, MCP scripts)  
**Branch:** `cursor/world-studio-gui-demo-recorder`  
**Agent:** `world_studio_builder`  
**Plan loop:** [2026-06-03-world-studio-gui-demo-recorder-loop.md](../docs/superpowers/plans/2026-06-03-world-studio-gui-demo-recorder-loop.md)

## Mission

**Control native Studio like Playwright controls a browser** — semantic API first, optional video second.

1. **UiSnapshot** — stable element IDs on the shell widget tree (not browser DOM)
2. **UiSession + MCP `ui_*`** — persistent headless compose; snapshot, click, key, wait, set_value
3. **DemoScript replay** — JSON steps drive real compose/input handlers (same path as MCP)
4. **Record** — frame capture on steps + wait interpolation → ffmpeg MP4 + `demo_trace.jsonl`
5. **Visual acceptance** — MP4s must show UI change, not pass on duration alone

Build on typography-fx + product-visual (`InputState`, `studio_vertical_capture_ppm_auto`, `ShellWidgetTree`).

## Phase 1 (W0–W7) — foundation ✅

Li APIs, MCP tool IDs, DemoScript types, encode scripts, scenario JSON, K8s bundle.  
**Gap:** shell replay still uses capture-smoke duplicate — see Phase 2.

## Phase 2 (W8–W11) — end-to-end ⏳

| WP | Deliverable |
|----|-------------|
| W8 | `UiSession` + `ui_session_start/stop` MCP |
| W9 | Real JSON replay runner; fix `studio-demo-replay.sh` |
| W10 | `demo_trace.jsonl` + MCP record parity with shell |
| W11 | Visual gate (unique_colors, frame delta) in completion gate |

## Progress gate

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
./scripts/world-studio-gui-demo-recorder-gates.sh
```

## Completion gate

```bash
./scripts/world-studio-gui-demo-recorder-gates.sh
./scripts/world-studio-gui-demo-recorder-completion-gate.sh
# Phase 2+: also
./scripts/studio-demo-visual-gate.sh
```

## Deliverables (every iteration)

1. Pick next pending `wrec-w*` (Phase 2: W8 → W11).
2. Implement native Li + MCP wiring as needed.
3. Run progress gate.
4. Replay scripts via **real JSON runner** → frames → MP4 under `build/demo-recorder/out/`.
5. Run visual gate on scenario MP4s.
6. Update `data/world-studio-gui-demo-recorder-loop/latest-videos.json` (paths/URLs, not binary blobs in git).
7. Write `latest-iteration-assessment.json` with **links to MP4s for Julian**.
8. Mark plan YAML todo `done`; push studio + lic branches.

## Acceptance scenarios (W6–W11)

| Script | Output MP4 | Visual proof |
|--------|------------|--------------|
| `data/demo-scripts/workspace-tour.demo.json` | `build/demo-recorder/out/workspace-tour.mp4` | Dock/region change visible |
| `data/demo-scripts/command-palette.demo.json` | `build/demo-recorder/out/command-palette.mp4` | Palette open after `cmd_k` |
| `data/demo-scripts/agent-invoke.demo.json` | `build/demo-recorder/out/agent-invoke.mp4` | Agent chrome state change |

Each MP4: duration ≥10s, unique_colors ≥48 on key frame, ≥1 frame pair differs mid-replay.

## Constraints

- **Native pixels only** — no HTML mock replay as product truth.
- **API control only for agents** — no vision/OCR loop in v1.
- MP4/ffmpeg artifacts **not committed** to git; manifest + provenance JSON only.
- New MCP tools must not expose arbitrary shell; allowlist only.
- Every new `def` has contracts.
