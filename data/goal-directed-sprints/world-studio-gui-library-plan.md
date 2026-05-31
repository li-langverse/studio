---
workflow_repo: studio
---

# Sprint: World Studio GUI library plan — Function·Layout·Design until done

**Repos:** `studio` (primary product), `lic` (secondary — `li-ui`, `li-gui`, `li-render`, `lig`)  
**Branch:** `cursor/world-studio-gui-library-plan`  
**Agent:** `world_studio_builder`  
**Plan hub:** [GUI-LIBRARY-PLAN.md](../docs/GUI-LIBRARY-PLAN.md)  
**Todo YAML:** [2026-05-31-world-studio-gui-library-plan-loop.md](../docs/superpowers/plans/2026-05-31-world-studio-gui-library-plan-loop.md)

## Mission

Implement [GUI-LIBRARY-PLAN.md](../docs/GUI-LIBRARY-PLAN.md) **Phases 0–5 completely** — the Li-native **Function · Layout · Design** GUI stack: tokens → PaintCmd IR → Widget/layout core → reactive compose → GPU rasterization → Li-owned present loop → installer-ready native binaries.

**Product truth:** Native Li World Studio GUI only. No HTML/CSS/JS product runtime. Retire duplicated C paint mirror in Phase 4.

## Cluster / premade image

Local Windows sprints use Git Bash + `li-cursor-agents` on the workstation. For K8s engine-cluster workers, use the premade toolchain image:

| Image | Role |
|-------|------|
| `ghcr.io/li-langverse/lic-ci:debian12-llvm22` | LLVM 22 + clang base (lic CI parity) |
| `ghcr.io/li-langverse/li-cursor-agents:latest` | Node 22 + li-cursor-agents runtime |

Pin via `li-cursor-agents/deploy/lic-ci-base.env`. Rebuild agent images when lic bumps LLVM.

## Phase status

Update each iteration. Mark `| **DONE** |` only when every `wsg-wN-*` todo in that wave is `status: done` in the plan YAML.

| Phase | Scope | Status |
|-------|-------|--------|
| **W0** | Styled chrome — PaintCmd round rects, typography tokens, studio_paint polish, native window not wireframe-only | **DONE** |
| **W1** | li-gui core — Widget protocol, flex/grid/scroll layout, EventDispatcher, base widgets, inspector pilot | **DONE** |
| **W2** | Reactive compose — Store/Derived, compose invalidation, migrate manual sync, ComposeCache | **DONE** |
| **W3** | Rasterization — font atlas, glyph PaintCmd ops, UI raster pass, wgpu viewport pixels, icon pipeline | pending |
| **W4** | Studio integration — Li-owned present loop, slim C host, full Widget tree, route table, headless golden | pending |
| **W5** | Installer-ready — Windows/macOS/Linux native hosts, CI installer matrix, perf budgets | pending |

## Progress gate

Per-iteration check (loop keeps going until ## Completion gate passes):

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
./scripts/world-studio-gui-plan-gates.sh
```

## Completion gate

Loop exits only when **all** pass:

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
./scripts/world-studio-gui-plan-completion-gate.sh
```

Gate requires: all `wsg-w*` todos `done` in plan YAML, progress gates pass, and Phase 0 minimum — **native window styled chrome** (not wireframe-only colored rects).

## Read first (in order)

1. `docs/GUI-LIBRARY-PLAN.md` — hub (Phases 0–5, Function·Layout·Design model)
2. `docs/design/studio-design-tokens.toml` — design source of truth
3. `docs/NATIVE-WINDOW.md` — present path
4. `../lic/packages/li-ui/README.md`, `../lic/packages/li-gui/README.md` — layout + input packages
5. `../lic/packages/lig/present/lib.li` — present contracts
6. `docs/superpowers/plans/2026-05-31-world-studio-gui-library-plan-loop.md` — **current todo**

## Agent environment

- **Windows:** run gates from `studio/` root; WSL `lic check` smokes when native `lic` unavailable (`WORLD_STUDIO_GATES_WSL=1`).
- **Secondary lic work:** commit GUI package changes on `lic` branch aligned with studio PR; keep `LIC_ROOT` sibling path.
- **Secrets:** load workspace `li/.env`, `li/.env.github`, `li-cursor-agents/.env` for `CURSOR_API_KEY` + `gh` (never log tokens).

## Deliverables (every iteration)

1. Pick next pending `wsg-w*` todo (wave order W0 → W5).
2. Implement in **native Li** — respect Function·Layout·Design layer boundaries.
3. Run `./scripts/world-studio-gui-plan-gates.sh`.
4. Write `data/world-studio-gui-plan-loop/latest-iteration-assessment.json` with `"native_only": true`.
5. Mark plan todo `done` when gates green; update **Phase status** table above.
6. Commit, push studio + lic branches; update PRs (do not open duplicates).

## Loop commands

```bash
cd studio && python3 ./scripts/world-studio-gui-plan-loop.py --once
cd li-cursor-agents && ./scripts/goal-directed-loop.sh \
  --agent world_studio_builder --workflow-repo studio --cwd ../studio \
  --goal-file ../data/goal-directed-sprints/world-studio-gui-library-plan.md --max 0
```

## Out of scope

- HTML studio runtime demos in `deploy/studio-demo/archive/`
- Embedding Qt, React, or Electron
- Merging to `main` without explicit user request

## Done when

`./scripts/world-studio-gui-plan-completion-gate.sh` exits 0 and phases **W0–W5** are **DONE** in the status table above.
