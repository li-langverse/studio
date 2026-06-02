---
workflow_repo: studio
---

# Sprint: World Studio GUI product-visual (fonts + shadows + real raster)

**Repos:** `studio` (primary), `lic` (secondary: `li-ui`, `li-gui`, `li-render`, `lig`)  
**Branch:** `cursor/world-studio-gui-product-visual`  
**Agent:** `world_studio_builder`  
**Plan hub:** `studio/docs/GUI-LIBRARY-PLAN.md`  
**Plan loop:** `studio/docs/superpowers/plans/2026-06-02-world-studio-gui-product-visual-loop.md`  

## Mission

Turn the current “nice wireframe” native Studio shell into a **product-quality native UI**:

- **Real text** (font atlas → `draw_glyphs`), not 5×7 glyphs / bit-bars
- **Elevation** (tokenized shadows + blur), not single-offset fills
- **Single pixel truth**: the SDL host presents pixels from the **Li rasterizer**, not the C `paint_fb` mirror
- **Proof + gates**: every iteration produces native screenshots and updates plan status

This sprint is explicitly **beyond** the W0–W5 GUI-library sprint; it targets “slick” visuals.

## Phase status

Update each iteration. Mark **DONE** only when *every* `wsv-wN-*` todo in that wave is `status: done`
in the plan YAML.

| Phase | Scope | Status |
|-------|-------|--------|
| **P0** | Raster truth (SDL host uses Li CPU raster) | pending |
| **P1** | Typography (TTF→atlas + readable labels) | pending |
| **P2** | Elevation (tokenized shadows + blur) | pending |
| **P3** | Icons + density (icon atlas, spacing rhythm) | pending |
| **P4** | Viewport polish (HUD text + honest pixels) | pending |
| **P5** | Acceptance (1280×720 + 7 vertical screenshots) | pending |

## Progress gate

```bash
set -euo pipefail
./scripts/world-studio-gui-product-visual-gates.sh
```

## Completion gate

```bash
set -euo pipefail
./scripts/world-studio-gui-product-visual-completion-gate.sh
```

## Deliverables each iteration

1. Pick next pending `wsv-w*` todo (in phase order).
2. Implement in native Li (no HTML product runtime).
3. Run progress gate.
4. Capture screenshots to:
   - `docs/demo/media/native-verticals/png/product-visual-<profile>.png`
   - `docs/demo/media/native-verticals/png/product-visual-<profile>-1280x720.png` (when applicable)
5. Update screenshot manifest:
   - `data/world-studio-gui-product-visual-loop/latest-screenshots.json`
6. Mark plan todo `done` in the plan YAML; update phase table above.

## Out of scope

- Embedding Qt/React/Electron
- HTML/CSS/JS Studio as product runtime
- Full HarfBuzz shaping/RTL (later sprint)

