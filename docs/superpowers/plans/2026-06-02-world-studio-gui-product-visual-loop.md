---
name: World Studio GUI product-visual loop
overview: Native Li-only product visual pass — fonts + elevation + honest raster. Uses Li headless raster capture for screenshots (no HTML runtime; no C paint mirror as “truth”).
todos:
  - id: wsv-w0-single-pixel-truth
    content: "W0 — Single pixel truth: screenshot gates capture pixels from Li rasterizer (studio_vertical_capture_ppm_auto), not C paint_fb mirror"
    status: done
  - id: wsv-w1-elevation-tokens
    content: "W1 — Elevation: tokenized shadows (and blur where supported) for panel chrome; subtle, consistent"
    status: pending
  - id: wsv-w2-text-polish
    content: "W2 — Text polish: labels and values align, readable at 12–14px, no placeholder rect text"
    status: pending
isProject: false
---

# World Studio GUI product-visual loop

**Agent:** `world_studio_builder`  
**Branch:** `cursor/world-studio-gui-product-visual`  
**Hub:** [GUI-LIBRARY-PLAN.md](../../GUI-LIBRARY-PLAN.md)

## Phase status

| Wave | Goal | Status |
|------|------|--------|
| W0 | Honest raster screenshots captured from Li pixels | done |
| W1 | Elevation tokens (shadows/blur) | pending |
| W2 | Text polish pass | pending |

## Gates

```bash
./scripts/world-studio-gui-product-visual-gates.sh
./scripts/world-studio-gui-product-visual-completion-gate.sh
```

