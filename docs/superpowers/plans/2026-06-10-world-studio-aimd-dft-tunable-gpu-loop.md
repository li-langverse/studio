---
name: World Studio AIMD DFT tunable + GPU loop
overview: Post-W7 sprint — tunable DFT eval frequency (dev stride 50 vs production stride 1), honest batch trace, and gpu_path=1 north star on engine GPU.
todos:
  - id: aimd-w8a-stride-config
    content: "W8a — dft_stride tunable via MCP/scenario JSON/env (default 50 dev, 1 for real)"
    status: completed
  - id: aimd-w8b-batch-stride1
    content: "W8b — Batch runner honors stride=1 → 5000 DFT calls when configured"
    status: completed
  - id: aimd-w8c-gpu-hot-path
    content: "W8c — GPU hot path on engine (gpu_path=1, chem_dft_gpu_path_available)"
    status: completed
  - id: aimd-w8d-hero-trace
    content: "W8d — Hero demo + trace manifest documents stride + dft_calls honestly"
    status: completed
  - id: aimd-w8e-completion-gate
    content: "W8e — Completion gate (stride=50 fast vs optional REAL_AIMD=1 slow 5000-DFT)"
    status: completed
isProject: false
---

# World Studio AIMD — tunable DFT stride + GPU north star

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development or superpowers:executing-plans. Pick next pending `aimd-w8*`; run progress gate each iteration.

**North star:** `gpu_path=1` on engine GPU with **real DFT every MD step** (`dft_stride=1`, 5000 DFT evals @ 5000 steps).

**Agent:** `world_studio_builder`  
**Branch:** `cursor/world-studio-aimd-dft-tunable-gpu` (studio + lic)  
**Sprint goal:** [world-studio-aimd-dft-tunable-gpu.md](../../../data/goal-directed-sprints/world-studio-aimd-dft-tunable-gpu.md)  
**Prior:** [2026-06-06-world-studio-aimd-demo-loop.md](2026-06-06-world-studio-aimd-demo-loop.md) (W0–W6), W7 GPU pilot on `main`

---

## DFT stride ladder

| Mode | `dft_stride` | DFT calls @ 5000 MD steps | Use |
|------|--------------|---------------------------|-----|
| **Dev / CI** | 50 (default) | 100 | Fast gates, agent iteration |
| **Real / production** | 1 | 5000 | Launch proof, engine GPU demo |

**Env knobs:**

| Variable | Effect |
|----------|--------|
| `STUDIO_AIMD_DFT_STRIDE` | Override stride (1–1000) |
| `REAL_AIMD=1` | Force `dft_stride=1` (production mode) |
| `hero-scenario.json` `"dft_stride"` | Default for batch scripts when env unset |

---

## Architecture delta (W8)

```text
aimd_configure_scenario ──► scenario.dft_stride (MCP + RT)
hero-scenario.json      ──► STUDIO_AIMD_DFT_STRIDE (shell)
REAL_AIMD=1             ──► stride 1 override
        │
        ▼
echem_aimd_batch_dft_stride() ──► li_rt_studio_aimd_dft_stride_from_env()
        │
        ▼
echem_aimd_batch_run ──► dft_calls counted in Li loop (honest)
        │
        ▼
batch-result.json + latest-demo-trace.json (dft_stride, dft_calls)
```

---

## Phase status

| WP | Scope | Status |
|----|-------|--------|
| **W8a** | MCP + scenario JSON + env stride | done |
| **W8b** | Batch stride=1 → 5000 DFT calls | done |
| **W8c** | Engine `gpu_path=1` | done |
| **W8d** | Hero trace honesty | done |
| **W8e** | Completion gate | done |

---

## W8a — Tunable `dft_stride`

**Deliverables:**

- [ ] `StudioAimdScenario.dft_stride` + `studio_mcp_tool_dispatch_aimd_configure_stride`
- [ ] `li_rt_studio_aimd_dft_stride_from_env()` — `REAL_AIMD`, `STUDIO_AIMD_DFT_STRIDE`, scenario default
- [ ] `hero-scenario.json` field `dft_stride: 50`
- [ ] `scripts/_studio-aimd-env.sh` resolver

**Done when:** MCP configure smoke green; env override changes batch `dft_stride` in trace.

---

## W8b — Batch honors stride=1

**Deliverables:**

- [ ] `echem_aimd_batch_dft_stride()` reads RT env (not hardcoded 50)
- [ ] `li_rt_studio_aimd_batch_write_json` takes actual `batch.dft_stride` + `batch.dft_calls`
- [ ] `echem_aimd_batch_stride_smoke.li` — 128 steps, stride 1 → 128 calls
- [ ] `studio-aimd-batch-run.sh` validates expected `dft_calls`

**Done when:** `REAL_AIMD=1` + 5000 steps → `dft_calls=5000` in `batch-result.json`.

---

## W8c — GPU hot path (`gpu_path=1`)

**Deliverables:**

- [ ] `chem_dft_gpu_path_available()` green on engine node (LKIR + science_gpu)
- [ ] Trace `gpu_path: 1` when engine GPU available; honest blocker in assessment when not
- [ ] Document `STUDIO_AIMD_GPU=1` for forced GPU preference where applicable

**Done when:** Engine K8s worker assessment shows `gpu_path=1` or documented `science_gpu_blocker`.

---

## W8d — Hero demo + trace honesty

**Deliverables:**

- [ ] `studio-aimd-hero-demo.sh` uses `_studio-aimd-env.sh`
- [ ] `latest-demo-trace.json` includes `dft_stride`, `dft_calls` from batch result
- [ ] Assessment JSON notes dev vs real tier

---

## W8e — Completion gate

```bash
./scripts/world-studio-aimd-dft-tunable-gpu-completion-gate.sh          # fast: stride 50
REAL_AIMD_COMPLETION=1 ./scripts/world-studio-aimd-dft-tunable-gpu-completion-gate.sh  # slow: 5000 DFT
```

**Done when:** Fast gate exit 0; slow gate optional for full production proof.

---

## Gates

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
./scripts/world-studio-aimd-demo-gates.sh
./scripts/world-studio-aimd-dft-tunable-gpu-completion-gate.sh
```

---

## K8s handoff

```powershell
cd li-cursor-agents
.\scripts\deploy-world-studio-aimd-demo-k8s.ps1 -KubeConfig "$env:USERPROFILE\.kube\config-homelab"
```

Worker: `li-world-studio-aimd-demo` · Branch: `cursor/world-studio-aimd-dft-tunable-gpu`
