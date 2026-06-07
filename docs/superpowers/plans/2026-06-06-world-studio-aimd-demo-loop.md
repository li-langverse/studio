---
name: World Studio AIMD hero demo loop
overview: GPU-accelerated AIMD simulation as launch hero demo — agent configures scenario via Studio chat/MCP, batch compute runs ~5000 steps headless (not step-by-step in demo), final state visualized in native viewport. MVP may use toy AIMD + GPU stub; plan marks path to real DFT-per-step coupling.
todos:
  - id: aimd-w0-audit-spec
    content: "W0 — Gap audit, hero scenario spec, gate scaffolding, cross-links to WP-ECHEM-09"
    status: done
  - id: aimd-w1-agent-mcp-flow
    content: "W1 — Agent chat/MCP flow: sim_scientific profile + AIMD scenario configure (algo, steps, temperature, potential)"
    status: done
  - id: aimd-w2-batch-compute
    content: "W2 — Headless batch AIMD runner ~5000 steps (decouple from 64-step interactive sim_scientific_tick_at cap)"
    status: done
  - id: aimd-w3-gpu-path
    content: "W3 — GPU AIMD compute path (science_gpu compile_open_ok, chem_dft batch kernel; stub→real ladder documented)"
    status: pending
  - id: aimd-w4-final-viz
    content: "W4 — Final-state viewport viz: load batch result, particle tier + scientific pipeline for last frame"
    status: pending
  - id: aimd-w5-e2e-demo
    content: "W5 — End-to-end demo script: agent chat → batch run → viewport snapshot; trace JSON for replay"
    status: pending
  - id: aimd-w6-completion-gate
    content: "W6 — Completion gate, hero manifest, K8s handoff verified; all acceptance smokes green"
    status: pending
isProject: false
---

# World Studio AIMD hero demo loop

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Pick next pending `aimd-w*`; run progress gate each iteration.

**North star (launch criterion):** GPU-accelerated AIMD simulation configured via agentic chat in native Li Studio, batch compute to ~5000 steps (not shown step-by-step in demo), final result in viewport.

**Agent:** `world_studio_builder`  
**Branch:** `cursor/world-studio-aimd-demo` (studio); lic changes on same branch when needed, else `main`  
**Sprint goal:** [world-studio-aimd-demo.md](../../../data/goal-directed-sprints/world-studio-aimd-demo.md)

---

## Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│  User / demo narrator — chat in Studio agent panel              │
└────────────────────────────┬────────────────────────────────────┘
                             │ natural language → MCP tools
┌────────────────────────────▼────────────────────────────────────┐
│  Control plane (fast, visible in demo)                          │
│  sim_set_profile(sim_scientific)                                │
│  aimd_configure_scenario { steps: 5000, algo: echem_aimd, ... } │
│  aimd_run_batch { headless: true }  → job_id                    │
└────────────────────────────┬────────────────────────────────────┘
                             │ same session; compute NOT step-shown
┌────────────────────────────▼────────────────────────────────────┐
│  Compute plane (batch / headless)                               │
│  echem_aimd_batch_run(steps=5000) → trajectory checkpoint        │
│  GPU: chem_dft_energy_kernel_hartree per MD step (stub→real)    │
└────────────────────────────┬────────────────────────────────────┘
                             │ final frame only
┌────────────────────────────▼────────────────────────────────────┐
│  Viz plane (demo payoff)                                        │
│  studio_sim_scientific_viz_for_tick(final) + viewport sync      │
│  headless PPM capture OR live viewport after batch complete     │
└─────────────────────────────────────────────────────────────────┘
```

**Playwright/recorder analogy:** Demo-recorder drives UI step-by-step for MP4. AIMD demo drives **chat + one batch job + final viz** — no 5000-frame replay.

---

## Current gaps (from audit)

| Gap | Location | WPs |
|-----|----------|-----|
| AIMD interface exists but 8 steps only | `echem_aimd_interface_smoke.li`, `echem_aimd_step_count()` | W2 |
| Interactive hook caps at 64 steps | `sim_scientific_tick_at` `requires step_index <= 64` | W2 |
| No agent→AIMD configure MCP | `studio_mcp_sim_set_profile` only; no `aimd_*` tools | W1 |
| GPU path separate from Studio demo | `ph-sci-gpu-chem-gates.sh`, WP-ECHEM-09 on lic | W3 |
| Viz is per-tick interactive, not batch final | `studio_sim_scientific_step_hook` | W4 |
| No end-to-end hero gate | — | W5, W6 |

**Existing assets to extend (do not reinvent):**

- WP-ECHEM-09: `algo_echem_aimd_interface` (433), `sim_scientific_oracle_checksum_echem_aimd()`
- `sim_scientific` profile: `studio_profile_sim_scientific()`, viewport particle tier sync
- Demo-recorder: `ui_session_*`, MCP stdio pattern (`scripts/lis-mcp-li-engine.py`)
- Electrochemistry plan: [ph-sci-electrochemistry-sim-plan.md](../../../../lic-chem-wt/data/goal-directed-sprints/ph-sci-electrochemistry-sim-plan.md)

---

## MVP vs real AIMD ladder

| Tier | Compute | GPU | Demo acceptable? |
|------|---------|-----|------------------|
| **MVP (W2–W3 stub)** | Toy harmonic + DFT energy stub per step; batch loop in Li | `compile_open_ok` smoke only | Yes for launch if labeled honest |
| **Pilot (post-W6)** | Real `chem_dft_energy_kernel_hartree` every N steps | science_gpu bench row | Stretch |
| **Real AIMD** | Full DFT per MD step, thermostat, drift oracle at 5000 | GPU kernel hot path | North star |

Plan todos must not claim real AIMD until W3 pilot gate passes. Document tier in `latest-iteration-assessment.json`.

---

## Phase status

| Phase | Scope | WPs | Status |
|-------|-------|-----|--------|
| **P0** | Audit + spec + gates | W0 | pending |
| **P1** | Agent MCP configure flow | W1 | pending |
| **P2** | Batch 5000-step compute | W2 | pending |
| **P3** | GPU path | W3 | pending |
| **P4** | Final-state visualization | W4 | pending |
| **P5** | E2E demo script | W5 | pending |
| **P6** | Completion + K8s | W6 | pending |

---

## W0 — Gap audit + hero scenario spec

**Deliverables:**

- [ ] `data/world-studio-aimd-demo-loop/hero-scenario.json` — steps=5000, profile=sim_scientific, algo=echem_aimd_interface
- [ ] `scripts/world-studio-aimd-demo-gates.sh` + completion gate stub
- [ ] Cross-link WP-ECHEM-09 smokes in gate (warn until green)

**Smokes (baseline must stay green):**

- `studio/li-tests/smoke/studio_mcp_tools.li`
- `lic/packages/li-sim-scientific/li-tests/smoke/echem_aimd_interface_smoke.li`

**Done when:** Plan + goal + gates exist; hero scenario JSON committed.

---

## W1 — Agent chat / MCP configure flow

**Problem:** Agent cannot configure AIMD scenario from chat; only `sim_set_profile` exists.

**Deliverables:**

- [ ] MCP tools (names provisional): `aimd_configure_scenario`, `aimd_get_scenario` — args: `{ steps, temperature_k, potential_v, algo_id }`
- [ ] Register in `studio_mcp_tool_*` + `scripts/lis-mcp-li-engine.py` allowlist
- [ ] Agent panel: map chat intent → tool dispatch (reuse `studio_agent_tool_request_for_run` pattern)
- [ ] Smoke: `studio/li-tests/smoke/studio_mcp_aimd_configure.li`

**Demo script fragment (chat → MCP):**

```text
User: "Run AIMD on the electrochemistry interface for 5000 steps at 300 K"
Agent: sim_set_profile(sim_scientific) → aimd_configure_scenario({ steps: 5000, temperature_k: 300 })
```

**Done when:** Headless MCP smoke configures scenario; `studio.toml` / session reflects settings.

---

## W2 — Batch headless compute (~5000 steps)

**Problem:** `sim_scientific_tick_at` requires `step_index <= 64`; demo needs batch path without interactive timeline.

**Deliverables:**

- [ ] `echem_aimd_batch_run(steps: int) -> AimdBatchResult` in `li-sim-scientific` (or studio wrapper)
- [ ] Separate batch entry from interactive hook — no 64 cap on batch API
- [ ] Checkpoint: final energy, drift, step count, checksum (not full trajectory in git)
- [ ] Smoke: `echem_aimd_batch_5000_smoke.li` — completes ≤60s on toy kernel (steps may be configurable down for CI, 5000 for demo gate)
- [ ] Shell: `scripts/studio-aimd-batch-run.sh` for CI/K8s

**Done when:** Batch smoke runs N steps (N≥5000 for demo gate, N≥64 for CI progress); returns deterministic checksum.

---

## W3 — GPU AIMD path

**Deliverables:**

- [ ] Wire batch loop to call `chem_dft_energy_kernel_hartree` (or GPU stub) each step
- [ ] `science_gpu` / `ph-sci-gpu-chem-gates.sh` subset in studio progress gate when LIC_ROOT available
- [ ] `AimdBatchResult.gpu_path: int` — 1 when GPU compile_open_ok, 0 CPU stub
- [ ] Document stub vs real in hero manifest

**Smokes:**

- `lic/packages/li-chem/li-tests/smoke/chem_gpu_che_h_ads.li` (compile_open_ok)
- Batch smoke reports `gpu_path == 1` when GPU gate available

**Done when:** Batch run selects GPU path when science_gpu green; honest fallback to CPU stub documented.

---

## W4 — Final-state visualization

**Deliverables:**

- [ ] `studio_aimd_load_final_state(batch_result) -> VizPipelineState`
- [ ] Viewport: `studio_set_particle_display` tier from final frame; `studio_sim_scientific_viz_for_tick(final_tick)`
- [ ] Headless capture: PPM of final frame under `build/aimd-demo/out/final-frame.ppm`
- [ ] Smoke: `studio/li-tests/smoke/studio_aimd_final_viz.li` — unique_colors ≥48, particle tier >0

**Done when:** After batch completes, viewport shows distinct final state (not empty grid).

---

## W5 — End-to-end demo script

**Deliverables:**

- [ ] `data/demo-scripts/aimd-hero.demo.json` — chat steps (configure only) + `aimd_run_batch` + `capture: final_frame`
- [ ] `scripts/studio-aimd-hero-demo.sh` — orchestrates MCP or in-process equivalent
- [ ] `data/world-studio-aimd-demo-loop/latest-demo-trace.json` — provenance (steps, checksum, gpu_path, frame path)
- [ ] Optional: reuse demo-recorder `ui_session_*` for agent panel visibility during configure phase

**Acceptance:**

- Demo completes without stepping through 5000 frames in UI
- Final PPM exists; manifest updated

**Done when:** Single shell script passes from clean tree; trace JSON committed (paths only).

---

## W6 — Completion gate + K8s

**Deliverables:**

- [ ] `scripts/world-studio-aimd-demo-completion-gate.sh` — all `aimd-w*` done + E2E script green
- [ ] `data/world-studio-aimd-demo-loop/latest-iteration-assessment.json`
- [ ] K8s worker `li-world-studio-aimd-demo` deployed (see sprint goal)

**Done when:** Completion gate exit 0; cluster worker scales down on success.

---

## Gates

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
./scripts/world-studio-aimd-demo-gates.sh
./scripts/world-studio-aimd-demo-completion-gate.sh   # sprint done
```

---

## File map

| Area | Path |
|------|------|
| Hero scenario | `studio/data/world-studio-aimd-demo-loop/hero-scenario.json` |
| Demo script | `studio/data/demo-scripts/aimd-hero.demo.json` |
| Batch runner | `studio/scripts/studio-aimd-batch-run.sh`, `studio/scripts/studio-aimd-hero-demo.sh` |
| Gates | `studio/scripts/world-studio-aimd-demo-*.sh` |
| Scientific core | `lic/packages/li-sim-scientific/src/lib.li`, `lic/packages/li-chem/src/lib.li` |
| Studio hooks | `studio/src/lib.li` — `studio_sim_scientific_*`, new `studio_aimd_*` |
| MCP | `scripts/lis-mcp-li-engine.py`, `lic/packages/li-studio/src/lib.li` |
| Manifest | `studio/data/world-studio-aimd-demo-loop/` |

---

## K8s handoff

```powershell
cd li-cursor-agents
.\scripts\deploy-world-studio-aimd-demo-k8s.ps1 -KubeConfig "$env:USERPROFILE\.kube\config-homelab"
```

Worker: `li-world-studio-aimd-demo` · Agent: `world_studio_builder` · Branch: `cursor/world-studio-aimd-demo`

---

## Out of scope (v1)

- Step-by-step 5000-frame demo replay or MP4 of MD trajectory
- Full grand-canonical AIMD (WP-ECHEM-12)
- wgpu 3D molecular mesh (particle tier dots OK for hero)
- HTML marketing demos
- Cloud HPC job queue (local/K8s batch only)

---

## Iteration checklist

1. Checkout `cursor/world-studio-aimd-demo` (studio + lic if needed)
2. Next pending `aimd-w*`
3. Run progress gate
4. If W5+: run hero demo script; update manifest
5. Mark plan YAML todo done; push studio (+ lic)
6. K8s worker continues until completion gate passes
