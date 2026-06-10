---
workflow_repo: studio
---

# Sprint: World Studio AIMD — tunable DFT stride + GPU north star

**Repo:** `studio` (+ `lic`: `li-sim-scientific`, `li-chem`, `science_gpu`, runtime)  
**Branch:** `cursor/world-studio-aimd-dft-tunable-gpu`  
**Agent:** `world_studio_builder`  
**Plan loop:** [2026-06-10-world-studio-aimd-dft-tunable-gpu-loop.md](../docs/superpowers/plans/2026-06-10-world-studio-aimd-dft-tunable-gpu-loop.md)

## Mission

Post-W7 pilot: make **DFT eval frequency tunable** (dev `dft_stride=50` → 101 calls; production `dft_stride=1` → 5000 calls @ 5000 MD steps) and pursue **`gpu_path=1`** on engine GPU via `chem_dft_gpu_path_available()`.

## Phase map

| WP | Deliverable | Status |
|----|-------------|--------|
| W8a | `dft_stride` via MCP/scenario JSON/env (`REAL_AIMD=1` → 1) | in_progress |
| W8b | Batch honors stride=1 → `dft_calls=5000` | in_progress |
| W8c | Engine GPU hot path `gpu_path=1` | pending |
| W8d | Hero demo trace documents stride + dft_calls | in_progress |
| W8e | Completion gate (fast 50 / optional slow 1) | in_progress |

## Progress gate

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
./scripts/world-studio-aimd-demo-gates.sh
```

## Completion gate

```bash
# Fast (CI / agent loop): stride 50, 101 DFT calls
./scripts/world-studio-aimd-dft-tunable-gpu-completion-gate.sh

# Slow (production proof): 5000 DFT evals
REAL_AIMD_COMPLETION=1 ./scripts/world-studio-aimd-dft-tunable-gpu-completion-gate.sh
```

## How to run

| Mode | Command | Expected trace |
|------|---------|------------------|
| **Dev (default)** | `./scripts/studio-aimd-hero-demo.sh` | `dft_stride=50`, `dft_calls=101` |
| **Real 5000-DFT** | `REAL_AIMD=1 ./scripts/studio-aimd-batch-run.sh` | `dft_stride=1`, `dft_calls=5000` |
| **Custom stride** | `STUDIO_AIMD_DFT_STRIDE=25 ./scripts/studio-aimd-batch-run.sh` | `dft_calls` per stride formula |

## Deliverables (every iteration)

1. Pick next pending W8* item from plan YAML.
2. Implement in `lic` (runtime, `li-sim-scientific`, `li-chem`) and `studio` (MCP, scripts, manifest).
3. Run progress gate; update `data/world-studio-aimd-demo-loop/latest-iteration-assessment.json`.
4. Push `studio` and `lic` to GitLab branch `cursor/world-studio-aimd-dft-tunable-gpu`.

## Acceptance

| Step | Proof |
|------|-------|
| Tunable stride | `echem_aimd_batch_stride_smoke` green; env changes `dft_stride` |
| Honest calls | `batch-result.json` `dft_calls` matches Li loop |
| Dev default | Gates pass at stride 50 without `REAL_AIMD` |
| Real mode | `REAL_AIMD=1` + 5000 steps → `dft_calls=5000` |
| GPU north star | `gpu_path=1` on engine or documented blocker |

## Constraints

- Dev/CI default remains `dft_stride=50` unless `REAL_AIMD=1`.
- Do not claim full GPU production AIMD until W8c engine proof lands.
- GitLab-primary: push branch to `gitlab.lilangverse.xyz/li-langverse/*`.
