---
name: World Studio GUI library plan loop
overview: Goal-directed agent executes GUI-LIBRARY-PLAN.md Phases 0–5 — Function·Layout·Design model, li-ui/li-gui/li-render stack, native styled chrome through installer-ready binaries.
todos:
  - id: wsg-w0-paint-ops
    content: "Phase 0 — PaintCmd fill_round_rect, stroke_round_rect, fill_gradient in li-ui"
    status: done
  - id: wsg-w0-typography-tokens
    content: "Phase 0 — typography + radius tokens from studio-design-tokens.toml → li-ui accessors"
    status: done
  - id: wsg-w0-studio-paint-polish
    content: "Phase 0 — studio_paint_* visual pass (dock icons, panel chrome, not wireframe rects)"
    status: done
  - id: wsg-w0-c-paint-parity
    content: "Phase 0 — C paint mirror parity for new ops (temporary until Phase 4)"
    status: done
  - id: wsg-w0-token-verify
    content: "Phase 0 — studio-ui-ux-verify-tokens.py extended verification green"
    status: done
  - id: wsg-w0-native-styled-chrome
    content: "Phase 0 — native window shows styled chrome (round rects/tokens), not wireframe-only"
    status: done
  - id: wsg-w1-widget-protocol
    content: "Phase 1 — Widget protocol (measure, layout, paint, handle_event) in li-gui"
    status: done
  - id: wsg-w1-layout-engines
    content: "Phase 1 — FlexLayout, GridLayout, PaddingLayout, ScrollLayout in li-gui"
    status: done
  - id: wsg-w1-event-dispatcher
    content: "Phase 1 — EventDispatcher hit-test tree + focus manager"
    status: done
  - id: wsg-w1-base-widgets
    content: "Phase 1 — Label, Button, Panel, ScrollArea, TextInput base widgets"
    status: done
  - id: wsg-w1-focus-model
    content: "Phase 1 — roving tabindex + studio_paint_focus_ring integration"
    status: done
  - id: wsg-w1-inspector-pilot
    content: "Phase 1 — migrate inspector region to Widget tree pilot"
    status: done
  - id: wsg-w2-store-primitives
    content: "Phase 2 — Store<T> / Derived<T> primitives in li-gui"
    status: done
  - id: wsg-w2-compose-deps
    content: "Phase 2 — @compose dependency annotations or convention-based invalidation graph"
    status: done
  - id: wsg-w2-migrate-sync
    content: "Phase 2 — migrate agent FSM, palette, timeline playhead, mode transitions off manual sync"
    status: done
  - id: wsg-w2-compose-cache
    content: "Phase 2 — ComposeCache dirty flags + partial re-compose smokes"
    status: done
  - id: wsg-w3-font-atlas
    content: "Phase 3 — Inter + ui-monospace font atlas (SDF or bitmap) at build time"
    status: done
  - id: wsg-w3-paintcmd-glyphs
    content: "Phase 3 — PaintCmd draw_glyphs, draw_image, clip_push/pop ops"
    status: done
  - id: wsg-w3-ui-raster
    content: "Phase 3 — li-render UI raster pass (CPU fallback + wgpu pipeline)"
    status: done
  - id: wsg-w3-wgpu-viewport-pixels
    content: "Phase 3 — real wgpu swapchain/readback pixels (WP-GD-05 Path A progress)"
    status: done
  - id: wsg-w3-icon-pipeline
    content: "Phase 3 — SVG → atlas icon pipeline referenced by token name"
    status: done
  - id: wsg-w4-present-loop
    content: "Phase 4 — li-studio-demo present loop calls Li rasterizer end-to-end"
    status: done
  - id: wsg-w4-c-host-slim
    content: "Phase 4 — C host slimmed to window/input/surface I/O only"
    status: done
  - id: wsg-w4-widget-tree-all-regions
    content: "Phase 4 — all shell regions on Widget tree + reactive stores"
    status: done
  - id: wsg-w4-route-table
    content: "Phase 4 — StudioRoute table for verticals/modes formalized"
    status: done
  - id: wsg-w4-headless-golden
    content: "Phase 4 — headless Li CPU rasterizer golden frames (no C paint mirror)"
    status: pending
  - id: wsg-w5-windows-native
    content: "Phase 5 — Windows native present host (Win32 or SDL static), no WSL requirement"
    status: pending
  - id: wsg-w5-macos-wgpu
    content: "Phase 5 — macOS aarch64 wgpu surface (PH-HW WP3 parallel track)"
    status: pending
  - id: wsg-w5-linux-appimage
    content: "Phase 5 — Linux AppImage with bundled SDL/wgpu"
    status: pending
  - id: wsg-w5-installer-ci
    content: "Phase 5 — installer build green on CI matrix (Windows + Linux)"
    status: pending
  - id: wsg-w5-perf-budgets
    content: "Phase 5 — viewport/UI perf budgets documented in release notes"
    status: pending
isProject: false
---

# World Studio GUI library plan loop

**Agent:** `world_studio_builder`  
**Branch:** `cursor/world-studio-gui-library-plan`  
**Hub:** [GUI-LIBRARY-PLAN.md](../../GUI-LIBRARY-PLAN.md)

**Primary repo:** `studio` (product shell, tokens, smokes)  
**Secondary repo:** `lic` (`li-ui`, `li-gui`, `li-render`, `lig` packages)
