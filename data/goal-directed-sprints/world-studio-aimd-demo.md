---
workflow_repo: studio
---

# Sprint: World Studio AIMD hero demo — GPU batch sim + agent chat + final viz

**Repo:** `studio` (+ `lic`: `li-sim-scientific`, `li-chem`, `li-studio`, MCP)  
**Branch:** `cursor/world-studio-aimd-demo`  
**Agent:** `world_studio_builder`  
**Plan loop:** [2026-06-06-world-studio-aimd-demo-loop.md](../docs/superpowers/plans/2026-06-06-world-studio-aimd-demo-loop.md)

## Mission (launch hero demo)

**GPU-accelerated AIMD simulation** as the flagship Studio use case:

1. **Agent configures scenario** via chat / MCP (profile, steps, temperature, potential)
2. **Compute runs ~5000 steps** in batch/headless mode — **not** shown step-by-step in the demo
3. **Visualize the final result** in the native viewport
4. Native Li Studio only — no HTML demos

Build on WP-ECHEM-09 (`echem_aimd_interface`), `sim_scientific` profile, demo-recorder MCP patterns, and GPU chem stubs.

## Phase map

| WP | Deliverable | Status |
|----|-------------|--------|
| W0 | Gap audit, hero scenario JSON, gate scaffolding | done |
| W1 | Agent chat → MCP AIMD configure flow | done |
| W2 | Batch headless ~5000-step AIMD runner (bypass 64-step interactive cap) | done |
| W3 | GPU path (science_gpu + chem DFT kernel; stub→real ladder) | done |
| W4 | Final-state viewport visualization | done |
| W5 | End-to-end demo script + trace manifest | pending |
| W6 | Completion gate + K8s verified | pending |

**MVP honesty:** Toy AIMD + GPU stub acceptable for first green gate if manifest declares tier; plan marks path to real DFT-per-step coupling.

## Progress gate

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
./scripts/world-studio-aimd-demo-gates.sh
```

## Completion gate

```bash
./scripts/world-studio-aimd-demo-completion-gate.sh
```

## Deliverables (every iteration)

1. Pick next pending `aimd-w*` (W0 → W6).
2. Implement native Li + MCP wiring in studio/lic as needed.
3. Run progress gate.
4. Update `data/world-studio-aimd-demo-loop/latest-iteration-assessment.json`.
5. W5+: run hero demo script; update `latest-demo-trace.json` (paths/checksums, not binary blobs in git).
6. Mark plan YAML todo `done`; push studio (+ lic if touched).

## Acceptance (hero demo)

| Step | Proof |
|------|-------|
| Agent configures AIMD via MCP | `studio_mcp_aimd_configure` smoke green |
| Batch 5000 steps (headless) | `echem_aimd_batch_*` smoke; no UI step loop |
| GPU path when available | `gpu_path: 1` in trace or documented CPU stub |
| Final viewport | `build/aimd-demo/out/final-frame.ppm` unique_colors ≥48 |
| E2E | `studio-aimd-hero-demo.sh` exit 0 |

## Constraints

- **Native pixels only** — no HTML mock as product truth.
- **Real gates/smokes** — not theater; stub tier must be labeled in assessment JSON.
- **No 5000-step UI replay** — batch compute off the hot path; demo shows configure + final viz.
- New MCP tools: allowlist only; no arbitrary shell.
- Every new `def` has contracts.

## Cross-links

| Resource | Path |
|----------|------|
| WP-ECHEM-09 AIMD interface | `lic/packages/li-sim-scientific/li-tests/smoke/echem_aimd_interface_smoke.li` |
| Electrochemistry plan | `lic/data/goal-directed-sprints/ph-sci-electrochemistry-sim-plan.md` |
| Demo-recorder MCP pattern | `studio/docs/superpowers/plans/2026-06-03-world-studio-gui-demo-recorder-loop.md` |
| Studio MCP tools | `studio/docs/game-dev/studio-mcp-tools.md` |
| Hero scenario | `data/world-studio-aimd-demo-loop/hero-scenario.json` |
