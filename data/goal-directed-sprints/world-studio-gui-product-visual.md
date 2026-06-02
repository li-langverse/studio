---
workflow_repo: studio
---

# Sprint: World Studio GUI product-visual — fonts + shadows + honest raster

**Repo:** `studio`  
**Branch:** `cursor/world-studio-gui-product-visual`  
**Agent:** `world_studio_builder`  
**Plan hub:** [GUI-LIBRARY-PLAN.md](../docs/GUI-LIBRARY-PLAN.md)  
**Plan loop:** [2026-06-02-world-studio-gui-product-visual-loop.md](../docs/superpowers/plans/2026-06-02-world-studio-gui-product-visual-loop.md)

## Mission

Turn the native Studio shell into a **product-quality native UI**:

- **Real text** (font atlas → `draw_glyphs`)
- **Elevation** (tokenized shadows + blur)
- **Single pixel truth**: SDL host presents pixels from **Li rasterizer**

## Progress gate

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
./scripts/world-studio-gui-product-visual-gates.sh
```

## Completion gate

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
./scripts/world-studio-gui-product-visual-completion-gate.sh
```

## Deliverables (every iteration)

1. Pick next pending `wsv-w*` todo (P0 → P5).
2. Implement in **native Li** (no HTML product runtime).
3. Run the progress gate (captures screenshots best-effort).
4. Capture screenshots to:
   - `docs/demo/media/native-verticals/png/product-visual-<profile>.png`
   - `docs/demo/media/native-verticals/png/product-visual-<profile>-1280x720.png` (when applicable)
5. Update screenshot manifest:
   - `data/world-studio-gui-product-visual-loop/latest-screenshots.json`
6. Write:
   - `data/world-studio-gui-product-visual-loop/latest-iteration-assessment.json`
7. Mark plan todo `done` in the YAML and update the phase status table in the loop doc.

