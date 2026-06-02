---
title: "World Studio GUI product-visual loop (fonts + shadows + raster truth)"
created_at: "2026-06-02"
---

# World Studio GUI product-visual loop

This plan is executed by the goal-directed sprint:
`studio/data/goal-directed-sprints/world-studio-gui-product-visual.md`

Todo IDs are `wsv-<phase>-<slug>`.

## P0 — Raster truth (Li owns pixels)

- id: wsv-p0-sdl-host-uses-li-raster
  content: "P0: Make SDL present host display RGBA8 produced by Li CPU raster (no C paint_fb mirror as default)"
  status: pending

- id: wsv-p0-c-paint-fb-fallback-only
  content: "P0: Keep C paint_fb mirror as explicit fallback (debug/CI), not the default pixel path"
  status: pending

## P1 — Typography (readable labels)

- id: wsv-p1-font-assets-and-tokens
  content: "P1: Add font assets + typography tokens (sizes/weights/line-height) and li-ui accessors"
  status: pending

- id: wsv-p1-build-font-atlas-msdf
  content: "P1: Build-time TTF→(MSDF/SDF) atlas + codegen to li-ui font_atlas_data (UV/metrics)"
  status: pending

- id: wsv-p1-replace-bit-bars-with-text
  content: "P1: Replace bit-bars/placeholder stripes in studio chrome with real draw_glyphs labels (dock/inspector/timeline/HUD)"
  status: pending

## P2 — Elevation (shadows + blur)

- id: wsv-p2-elevation-tokens
  content: "P2: Elevation tokens (sm/md/lg) and per-panel elevation roles"
  status: pending

- id: wsv-p2-drop-shadow-paintcmd
  content: "P2: Add drop-shadow PaintCmd + separable blur (CPU first) and apply to dock/inspector/timeline/agent"
  status: pending

## P3 — Icons + density

- id: wsv-p3-icon-atlas
  content: "P3: Icon atlas pipeline (SVG/PNG → atlas) + draw_image PaintCmd; bind to design roles"
  status: pending

- id: wsv-p3-spacing-rhythm
  content: "P3: Spacing/typography rhythm pass (padding, gaps, headers, row density) using tokens (no magic numbers)"
  status: pending

## P4 — Viewport polish

- id: wsv-p4-viewport-hud-text
  content: "P4: Viewport HUD uses real labels (grid legend, profile, fps) via draw_glyphs"
  status: pending

- id: wsv-p4-native-pixels-honesty
  content: "P4: Ensure native_pixels honesty is true for wgpu path; keep CPU path honest for CI"
  status: pending

## P5 — Acceptance (screenshots + gates)

- id: wsv-p5-screenshot-suite
  content: "P5: Produce and check in product-visual PNG suite (1280×720 + verticals) and update screenshot manifest"
  status: pending

- id: wsv-p5-gates-and-completion
  content: "P5: Gates enforce readable text + elevation + screenshot entropy; completion gate exits 0"
  status: pending

