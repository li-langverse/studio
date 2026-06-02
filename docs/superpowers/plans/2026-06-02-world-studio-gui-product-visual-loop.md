---
name: World Studio GUI product-visual loop
title: "World Studio GUI product-visual loop (fonts + shadows + raster truth)"
created_at: "2026-06-02"
overview: >
  Product-quality native UI visuals for World Studio (fonts + elevation + honest raster path).
  Native Li only — HTML under deploy/studio-demo/ is marketing-only and never counts as product proof.
todos:
  - id: wsv-w0-raster-truth
    content: "P0 — Single pixel truth: SDL host presents pixels produced by Li rasterizer (no C paint_fb mirror / paint_blit capture)"
    status: done
  - id: wsv-w1-typography-real-text
    content: "P1 — Real text: font atlas + draw_glyphs used for shell labels (not bitmap 5×7 / bars)"
    status: pending
  - id: wsv-w2-elevation-shadows
    content: "P2 — Elevation: tokenized shadows with blur (not single-offset fill only); panels read as layered surfaces"
    status: pending
  - id: wsv-w3-icons-density
    content: "P3 — Icons + density: icon atlas tokens + spacing rhythm; no placeholder squares; consistent 4/8px grid"
    status: pending
  - id: wsv-w4-viewport-polish
    content: "P4 — Viewport polish: HUD text + honest pixels in viewport overlays; no fake checkerboard-only proofs"
    status: pending
  - id: wsv-w5-acceptance-screenshots
    content: "P5 — Acceptance: 1280×720 + 7 vertical screenshots captured to docs/demo/media/native-verticals/png/product-visual-*.png and manifest updated"
    status: pending
isProject: false
---

# World Studio GUI product-visual loop

**Agent:** `world_studio_builder`  
**Branch:** `cursor/world-studio-gui-product-visual`  
**Hub:** [GUI-LIBRARY-PLAN.md](../../GUI-LIBRARY-PLAN.md)  
**Primary repo:** `studio`  
**Secondary repo:** `lic` (`li-ui`, `li-gui`, `li-render`, `lig`)

## Phase status

Mark **DONE** only when every `wsv-wN-*` todo in that wave is `status: done`.

| Phase | Scope | Status |
|-------|-------|--------|
| **P0** | Raster truth (SDL host uses Li raster) | done |
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

