# Sprint: Li World Studio runnable on Windows + installer

**Repos:** `lic` (primary), `li` workspace (goal + launchers), `li-cursor-agents` (runtime)  
**Branch:** `cursor/world-studio-runnable-installer` (or `cursor/world-studio-master-plan-loop`)  
**Agent:** `world_studio_builder`

## Mission

Ship a **native** `li-studio-demo` that runs on Windows 10/11 (WSL or native `lic` build), with SDL present host optional, plus a **branded Inno Setup** installer (not HTML demo).

## Phase table

| Phase | Scope | Status |
|-------|-------|--------|
| **W0** | `lic` build (LLVM 22), `emit.cpp` f64→f32 `CallProc`, workspace `li-sim-sensors` | **DONE** |
| **W1** | `li-studio-demo` build, sim tick in `studio_vertical_demo_frame`, PowerShell launcher | **DONE** |
| **W2** | Inno Setup installer, completion gate script, sprint loop | **DONE** |

## Progress gate

Lighter than full master plan — studio runnable slice only:

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
./scripts/world-studio-runnable-gate.sh
```

From repo root (`li`):

```powershell
.\scripts\start-li-world-studio.ps1 -CheckOnly
```

## Completion gate

Loop exits when **all** pass:

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
bash scripts/world-studio-runnable-completion-gate.sh
```

## Read first

1. `lic/README.md` — build/run `li-studio-demo`
2. `lic/docs/release-notes/2026-05-30-studio-timeline-sim-tick-sync.md`
3. `lic/installer/README.md` — Inno Setup build
4. `scripts/start-li-world-studio.ps1` — Windows launcher

## Deliverables (agent)

- Green `world-studio-runnable-gate.sh` when `lic` available
- `build/li-studio-demo` (+ `.exe` on Windows)
- `installer/out/LiWorldStudio-Setup.exe` when `iscc` installed
- PR or update to [#411](https://github.com/li-langverse/studio/pull/411) with runnable + installer commits

## Environment

- **Windows:** `build-wsl/compiler/lic/lic` preferred; `LIG_HOST_PRESENT=1` needs SDL2 on PATH
- **WSL build:** `bash scripts/wsl-setup-build.sh` or existing `build-wsl/`
- **Secrets:** load `li/.env` + `li/.env.github` for `gh` (never log tokens)
