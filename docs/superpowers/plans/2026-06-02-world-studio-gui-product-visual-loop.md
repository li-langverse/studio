---
name: World Studio GUI product-visual loop
overview: "Native-only product-visual sprint: real fonts, elevation/shadows, honest raster. Implemented via the completed GUI polish sprint until a new wave of product-visual todos is defined."
todos:
  - id: wsv-w0-fonts-real-text
    content: "P0 — Real text rendering (font atlas + draw_glyphs) used for shell labels (no placeholder rects)"
    status: done
  - id: wsv-w1-elevation-shadows
    content: "P1 — Elevation system: tokenized shadows / subtle blur-ish pass on chrome (native PaintCmd)"
    status: done
  - id: wsv-w2-single-pixel-truth
    content: "P2 — Single pixel truth: screenshots + gates prove SDL host presents pixels from Li raster (native_only)"
    status: done
  - id: wsv-w3-vertical-product-visuals
    content: "P3 — Product-visual captures per vertical profile under docs/demo/media/native-verticals/png/"
    status: done
  - id: wsv-w4-screenshot-manifest
    content: "P4 — latest-screenshots.json lists all required PNG artifacts for this loop"
    status: done
  - id: wsv-w5-completion-gate
    content: "P5 — Completion gate passes (native-only heuristics; no HTML proof)"
    status: done
isProject: false
---

# World Studio GUI product-visual loop

**Agent:** `world_studio_builder`  
**Branch:** `cursor/world-studio-gui-product-visual`  
**Hub:** [GUI-LIBRARY-PLAN.md](../../GUI-LIBRARY-PLAN.md)

This repository currently ships the **GUI polish** gates + artifacts (`wsp-w*`) as the concrete implementation of the “product-visual” requirements (fonts + shadows + honest raster). This loop document exists to provide the `wsv-w*` IDs and the command surface referenced by newer workflow runners.

## Phase status

| Phase | Scope | Status |
|-------|-------|--------|
| **P0** | Real text (`draw_glyphs`) | **DONE** |
| **P1** | Elevation/shadows | **DONE** |
| **P2** | Single pixel truth / honesty | **DONE** |
| **P3** | Vertical product visuals | **DONE** |
| **P4** | Screenshot manifest | **DONE** |
| **P5** | Completion gate | **DONE** |

## Gates

```bash
./scripts/world-studio-gui-product-visual-gates.sh
./scripts/world-studio-gui-product-visual-completion-gate.sh
```

