---
workflow_repo: studio
---

# Sprint: World Studio typography · FX · animation

**Repo:** `studio` (+ `lic` packages `li-ui`, `li-gui`)  
**Branch:** `cursor/world-studio-typography-fx-animation`  
**Agent:** `world_studio_builder`  
**Plan hub:** [GUI-LIBRARY-PLAN.md](../docs/GUI-LIBRARY-PLAN.md)  
**Plan loop:** [2026-06-03-world-studio-typography-fx-animation-loop.md](../docs/superpowers/plans/2026-06-03-world-studio-typography-fx-animation-loop.md)

## Mission

Harden the **typography engine** with a real **Li test matrix**, then ship **mathematically adjustable** UI effects and **token-driven animations**:

1. **Typography** — metrics, baselines, glyph-run bounds (not token-only smokes)
2. **Opacity** — `Color.a` + source-over compositing in raster
3. **Shadows** — parameterized multi-layer elevation from tokens
4. **Diffusion** — separable blur on shadow layers (sigma/radius from tokens)
5. **Motion** — easing library + panel/hover/overlay transitions from `[motion]` tokens

Build on product-visual (`draw_glyphs`, elevation stubs). Do **not** regress raster truth (Li raster is product path).

## Progress gate

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
./scripts/world-studio-typography-fx-animation-gates.sh
```

## Completion gate

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
./scripts/world-studio-typography-fx-animation-completion-gate.sh
```

## Deliverables (every iteration)

1. Pick next pending `wtfx-w*` todo (P0 → P5).
2. Implement in **native Li** (`lic` + `studio`); sync `li-ui` / `li-gui` if needed.
3. Run progress gate; fix failures before marking todo done.
4. Capture screenshots to:
   - `docs/demo/media/native-verticals/png/typography-fx-game-1280x720.png`
   - `docs/demo/media/native-verticals/png/typography-fx-game.png`
   - `docs/demo/media/native-verticals/png/typography-fx-inspector-panel.png`
   - `docs/demo/media/native-verticals/png/typography-fx-palette-overlay.png`
5. Update `data/world-studio-typography-fx-animation-loop/latest-screenshots.json`
6. Write `data/world-studio-typography-fx-animation-loop/latest-iteration-assessment.json`
7. Mark plan todo `done` in YAML; update phase table in loop doc.
8. Push `cursor/world-studio-typography-fx-animation` on **studio** and **lic**.

## Constraints

- All new effect parameters live in `docs/design/studio-design-tokens.toml` with matching `studio_*()` accessors.
- Every new exported `def` has `requires` / `ensures` / `decreases`.
- No HTML as product runtime.
- Respect `motion_reduced()` stub (snap transitions when enabled).
