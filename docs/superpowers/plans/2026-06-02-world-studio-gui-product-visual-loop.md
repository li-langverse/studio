---
name: World Studio GUI product-visual loop
overview: Goal-directed sprint — push the native Li Studio shell from “nice wireframe” to product-quality visuals (real text, elevation/shadows, single pixel truth). Screenshot-gated; HTML mocks are reference only.
todos:
  - id: wsv-w0-raster-truth
    content: "W0 — Raster truth: SDL host presents pixels from Li rasterizer (no C paint_fb mirror as product truth)"
    status: done
  - id: wsv-w1-typography-font-atlas
    content: "W1 — Typography: real text via font atlas + draw_glyphs (no 5×7 glyphs / bit-bars) for key chrome labels"
    status: done
  - id: wsv-w2-elevation-shadows
    content: "W2 — Elevation: tokenized shadows + blur (subtle) on panels; consistent depth model across shell regions"
    status: done
  - id: wsv-w3-icons-density
    content: "W3 — Icons + density: icon atlas + spacing rhythm; dock/topbar/tooling feels compact and readable"
    status: done
  - id: wsv-w4-viewport-polish
    content: "W4 — Viewport polish: HUD text + honest pixels; overlays match product chrome quality"
    status: done
  - id: wsv-w5-acceptance-screenshots
    content: "W5 — Acceptance: 1280×720 + 7 vertical screenshots; manifest updated; completion gate passes"
    status: done
isProject: false
---

# World Studio GUI product-visual loop

**Agent:** `world_studio_builder`  
**Branch:** `cursor/world-studio-gui-product-visual`  
**Hub:** [GUI-LIBRARY-PLAN.md](../../GUI-LIBRARY-PLAN.md)

## Mission (product-quality native UI)

- **Real text** (font atlas → `draw_glyphs`), not 5×7 glyphs / bit-bars
- **Elevation** (tokenized shadows + blur), not single-offset fills
- **Single pixel truth**: the SDL host presents pixels from the **Li rasterizer**, not the C `paint_fb` mirror
- **Proof + gates**: each iteration produces native screenshots and updates plan status

## Phase status

Update each iteration. Mark **DONE** only when every `wsv-w*` todo in that wave is `status: done` in the YAML above.

| Phase | Scope | Status |
|-------|-------|--------|
| **P0** | Raster truth (SDL host uses Li raster) | **DONE** |
| **P1** | Typography (TTF→atlas + readable labels) | **DONE** |
| **P2** | Elevation (tokenized shadows + blur) | **DONE** |
| **P3** | Icons + density (icon atlas, spacing rhythm) | **DONE** |
| **P4** | Viewport polish (HUD text + honest pixels) | **DONE** |
| **P5** | Acceptance (1280×720 + 7 vertical screenshots) | **DONE** |

## Gates

```bash
set -euo pipefail
./scripts/world-studio-gui-product-visual-gates.sh
./scripts/world-studio-gui-product-visual-completion-gate.sh
```

