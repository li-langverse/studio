---
name: World Studio GUI polish loop
overview: Goal-directed polish sprint — native Li World Studio from wireframe+ structure to slick, readable, interactive product chrome (Function · Layout · Design). Screenshot-gated; HTML mocks are reference only.
todos:
  - id: wsp-w0-typography-readable
    content: "W0 — Typography readable at 12–14px body; token contrast WCAG-ish on shell chrome"
    status: done
  - id: wsp-w0-token-contrast
    content: "W0 — surface/text/border tokens applied consistently; no raw gray wireframe fills"
    status: done
  - id: wsp-w0-anti-wireframe-paint
    content: "W0 — paint_fb / studio_paint anti-wireframe pass (round rects, elevation, not flat blocks)"
    status: done
  - id: wsp-w0-baseline-screenshot
    content: "W0 — polish-baseline vs iteration-0 screenshot diff documented in assessment JSON"
    status: done
  - id: wsp-w1-glyph-pipeline
    content: "W1 — glyph pipeline wired; draw_glyphs used for shell labels (not placeholder rects)"
    status: done
  - id: wsp-w1-inspector-labels
    content: "W1 — inspector shows real field labels + values (drug_litl pilot minimum)"
    status: done
  - id: wsp-w1-dock-icons
    content: "W1 — dock/toolbar icons from atlas by token name (not colored squares)"
    status: done
  - id: wsp-w1-viewport-overlays
    content: "W1 — viewport HUD overlays (mode, selection, grid legend) readable"
    status: done
  - id: wsp-w2-hover-states
    content: "W2 — hover states visible on buttons, list rows, timeline clips"
    status: done
  - id: wsp-w2-focus-ring
    content: "W2 — focus ring + keyboard nav feedback on interactive controls"
    status: done
  - id: wsp-w2-shortcut-hints
    content: "W2 — command palette / shortcut hints visible where spec’d"
    status: done
  - id: wsp-w3-viewport-grid
    content: "W3 — viewport grid + axes polish (not debug placeholder lines)"
    status: done
  - id: wsp-w3-particles-sim
    content: "W3 — particles / sim viz stub replaced with profile-appropriate preview"
    status: done
  - id: wsp-w3-game-profile-viz
    content: "W3 — game profile 1280×720 viewport content not empty checkerboard only"
    status: done
  - id: wsp-w4-gradients-shadows
    content: "W4 — gradients + subtle shadows on panels (native PaintCmd, no HTML)"
    status: pending
  - id: wsp-w4-spacing-rhythm
    content: "W4 — 4/8px spacing rhythm on shell regions; align to design tokens"
    status: pending
  - id: wsp-w4-vertical-polish
    content: "W4 — per-vertical chrome pass (game, sim_rl, sim_drug_design minimum)"
    status: pending
  - id: wsp-w5-polish-png-set
    content: "W5 — polish-*.png per vertical under docs/demo/media/native-verticals/png/"
    status: pending
  - id: wsp-w5-game-1280x720
    content: "W5 — polish-game-1280x720.png captured at full HD game profile"
    status: pending
  - id: wsp-w5-screenshot-manifest
    content: "W5 — latest-screenshots.json lists all polish paths + iteration PNGs"
    status: pending
  - id: wsp-w5-no-html-proof
    content: "W5 — completion gate rejects HTML-only proof; native PNG size/heuristic pass"
    status: pending
isProject: false
---

# World Studio GUI polish loop

**Agent:** `world_studio_builder`  
**Branch:** `cursor/world-studio-gui-polish`  
**Hub:** [GUI-LIBRARY-PLAN.md](../../GUI-LIBRARY-PLAN.md)  
**Prior sprint:** `world-studio-gui-library` (`wsg-w*`) — stack landed; visuals still low-fi.

**Primary repo:** `studio`  
**Secondary repo:** `lic` (glyphs, li-ui, li-render as needed)

## Assessment intro (carry into every PR)

Native landed screenshot (~640×360, ~4 KB) proves **layout regions work** but is **not slick** vs HTML mock (~385 KB) or Qt/Svelte/Next Figma bars. This loop closes the **visual + interaction gap** on native Li only.

## Wave map

| Wave | Exit criteria |
|------|----------------|
| W0 | Readable type, token contrast, anti-wireframe paint; baseline diff |
| W1 | Glyphs, inspector labels, dock icons, viewport overlays |
| W2 | Hover/focus/shortcut feedback visible |
| W3 | Viewport grid/sim/game preview not placeholder |
| W4 | Gradients, shadows, spacing rhythm; 3 verticals polished |
| W5 | `polish-*.png` + 1280×720 game; manifest + completion gate |

## Gates

```bash
./scripts/world-studio-gui-polish-gates.sh
./scripts/world-studio-gui-polish-completion-gate.sh
```
