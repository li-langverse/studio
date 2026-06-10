---
workflow_repo: studio
---

# Sprint: World Studio AIMD GPU pilot — real chem_dft path on main

**Repo:** `studio` (+ `lic`: `li-chem`, `li-sim-scientific`, `science_gpu`)  
**Branch:** `main`  
**Agent:** `world_studio_builder`  
**Plan loop:** [2026-06-06-world-studio-aimd-demo-loop.md](../docs/superpowers/plans/2026-06-06-world-studio-aimd-demo-loop.md) (post-W6 pilot tier)

## Mission

Advance from stub-tier AIMD (W0–W6 merged on `main`) to **GPU pilot**: real `chem_dft_energy_kernel_hartree` every N MD steps when `science_gpu` gates are green; honest CPU fallback documented.

## Phase map

| WP | Deliverable | Status |
|----|-------------|--------|
| W7a | Pilot gate: `ph-sci-gpu-chem-gates.sh` subset + `gpu_path` trace on main | pending |
| W7b | Batch loop calls real DFT kernel every N steps (not every step) | pending |
| W7c | `latest-iteration-assessment.json` tier=`pilot`; hero demo re-run on GPU when available | pending |

## Progress gate

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
./scripts/world-studio-aimd-demo-gates.sh
```

## Completion gate

```bash
./scripts/world-studio-aimd-demo-completion-gate.sh
# Pilot done when batch trace reports gpu_path==1 OR assessment documents honest CPU stub with science_gpu blocker
```

## Deliverables (every iteration)

1. Pick next pending W7* item.
2. Implement in `lic` (`li-chem`, `science_gpu`) and wire in studio batch runner.
3. Run progress gate; update `data/world-studio-aimd-demo-loop/latest-iteration-assessment.json` with tier `pilot`.
4. Push `studio` and `lic` to GitLab `main` (MR if needed).

## Acceptance (pilot)

| Step | Proof |
|------|-------|
| science_gpu compile_open_ok | `lic` chem GPU smoke green when engine GPU available |
| Real kernel in batch | `chem_dft_energy_kernel_hartree` invoked every N steps |
| Trace honesty | `latest-demo-trace.json` has `gpu_path: 1` or documented fallback |
| E2E | `studio-aimd-hero-demo.sh` exit 0 on main |

## Constraints

- Work on `main` only post-merge (studio#79, lic#874).
- Do not claim full real AIMD (5000-step full DFT) until pilot gate passes.
- Native Li Studio only; stub tier must be labeled in assessment JSON.
