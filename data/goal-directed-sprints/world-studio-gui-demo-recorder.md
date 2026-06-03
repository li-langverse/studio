---
workflow_repo: studio
---

# Sprint: World Studio GUI demo recorder — MCP control + native MP4

**Repo:** `studio` (+ `lic`: `li-gui`, `li-studio`, MCP scripts)  
**Branch:** `cursor/world-studio-gui-demo-recorder`  
**Agent:** `world_studio_builder`  
**Plan loop:** [2026-06-03-world-studio-gui-demo-recorder-loop.md](../docs/superpowers/plans/2026-06-03-world-studio-gui-demo-recorder-loop.md)

## Mission

Enable **agents to control the native Studio GUI** and **deliver demo MP4 videos**:

1. **UiSnapshot** — stable element IDs on the shell widget tree (not browser DOM)
2. **MCP `ui_*` tools** — snapshot, click, key, wait, set_value on `lis mcp li-engine`
3. **DemoScript replay** — JSON step lists drive real compose/input handlers
4. **Capture + ffmpeg** — native PNG frames → H.264 MP4 + provenance
5. **Deliver videos** — manifest with paths/URLs for human review (not MP4 in git)

Build on typography-fx + product-visual (`InputState`, `studio_vertical_capture_ppm_auto`, `ShellWidgetTree`).

## Progress gate

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
./scripts/world-studio-gui-demo-recorder-gates.sh
```

## Completion gate

```bash
./scripts/world-studio-gui-demo-recorder-completion-gate.sh
```

## Deliverables (every iteration)

1. Pick next pending `wrec-w*` (P0 → P7).
2. Implement native Li + MCP wiring as needed.
3. Run progress gate.
4. For W4+: replay scripts → PNG frames → MP4 under `build/demo-recorder/out/`.
5. Update `data/world-studio-gui-demo-recorder-loop/latest-videos.json` (paths/URLs, not binary blobs in git).
6. Write `latest-iteration-assessment.json` with **links to MP4s for Julian**.
7. Mark plan YAML todo `done`; push studio + lic branches.

## Acceptance scenarios (W6–W7)

| Script | Output MP4 |
|--------|------------|
| `data/demo-scripts/workspace-tour.demo.json` | `build/demo-recorder/out/workspace-tour.mp4` |
| `data/demo-scripts/command-palette.demo.json` | `build/demo-recorder/out/command-palette.mp4` |
| `data/demo-scripts/agent-invoke.demo.json` | `build/demo-recorder/out/agent-invoke.mp4` |

## Constraints

- **Native pixels only** — no HTML mock replay as product truth.
- MP4/ffmpeg artifacts **not committed** to git; manifest + provenance JSON only.
- New MCP tools must not expose arbitrary shell; allowlist only.
- Every new `def` has contracts.
