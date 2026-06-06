---
name: World Studio typography FX animation loop
overview: Goal-directed sprint — harden the typography engine with a real Li test matrix, add mathematically parameterized visual effects (opacity, shadows, diffusion/blur), and wire token-driven UI animations. Screenshot- and smoke-gated; hands off to homelab K8s world_studio_builder.
todos:
  - id: wtfx-w0-typography-tests
    content: "W0 — Typography engine: metrics invariants + expanded li-tests (atlas, shaping, line height, truncation)"
    status: done
  - id: wtfx-w1-typography-raster
    content: "W1 — Typography raster: glyph run bounds, subpixel advances, baseline alignment across shell regions"
    status: done
  - id: wtfx-w2-opacity-compositing
    content: "W2 — Opacity: Color.a math + source-over compositing in CPU raster (PaintCmd + blit path)"
    status: done
  - id: wtfx-w3-shadow-math
    content: "W3 — Shadows: tokenized multi-layer elevation as pure functions; smokes prove offset/alpha falloff"
    status: done
  - id: wtfx-w4-diffusion-blur
    content: "W4 — Diffusion: separable Gaussian/box blur on shadow layers (sigma from tokens); bounded cost"
    status: done
  - id: wtfx-w5-motion-core
    content: "W5 — Motion core: frame clock, easing library, tween structs with requires/ensures"
    status: done
  - id: wtfx-w6-shell-transitions
    content: "W6 — Shell transitions: panel/hover/overlay animate from [motion] tokens (respect reduced-motion)"
    status: done
  - id: wtfx-w7-acceptance
    content: "W7 — Acceptance: FX demo screenshots + completion gate; plan YAML all done"
    status: done
isProject: false
---

# World Studio typography · FX · animation loop

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Pick the next pending `wtfx-w*` todo; run progress gate every iteration; mark todo `done` only when its section checklist is complete.

**Goal:** Ship a **proof-friendly typography engine** and **mathematically adjustable** UI effects (opacity, shadows, diffusion) plus **token-driven animations**, integrated into native Studio chrome.

**Architecture:** Extend `li-ui` (tokens, PaintCmd, font atlas, raster) and `li-gui` (motion helpers); consume from `studio` painters. All effect parameters come from `studio-design-tokens.toml` with Li accessors and smokes — no magic numbers in paint procs. Animations interpolate stored scalars via easing functions keyed off a monotonic frame clock.

**Tech Stack:** Li (`def` + contracts), `lic check` / `lic build`, CPU raster (`paint_blit` / Li raster truth), optional future wgpu UI pass (out of scope unless W4 blit path is shared).

**Hub:** [GUI-LIBRARY-PLAN.md](../../GUI-LIBRARY-PLAN.md) · **Prior sprint:** [2026-06-02-world-studio-gui-product-visual-loop.md](2026-06-02-world-studio-gui-product-visual-loop.md)

**Agent:** `world_studio_builder`  
**Branch:** `cursor/world-studio-typography-fx-animation`  
**Sprint goal:** [world-studio-typography-fx-animation.md](../../../data/goal-directed-sprints/world-studio-typography-fx-animation.md)

---

## Phase status

Update each iteration. Mark **DONE** only when every `wtfx-w*` in that phase is `status: done` in the YAML above.

| Phase | Scope | WPs | Status |
|-------|-------|-----|--------|
| **P0** | Typography tests + metrics engine | W0–W1 | DONE |
| **P1** | Opacity + compositing | W2 | DONE |
| **P2** | Shadows + diffusion (mathematical FX) | W3–W4 | DONE |
| **P3** | Motion + easing + animation clock | W5 | DONE |
| **P4** | Shell integration (transitions) | W6 | DONE |
| **P5** | Acceptance (screenshots + gates) | W7 | DONE |

---

## Gates (every iteration)

```bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
./scripts/world-studio-typography-fx-animation-gates.sh
```

Completion (sprint done):

```bash
./scripts/world-studio-typography-fx-animation-completion-gate.sh
```

---

## File map (primary touch points)

| Area | Path | Responsibility |
|------|------|----------------|
| Tokens | `docs/design/studio-design-tokens.toml` | `[typography]`, `[elevation]`, new `[fx]`, `[motion]`, `[animation]` |
| Token verify | `scripts/studio-ui-ux-verify-tokens.py` | Assert new sections ↔ Li accessors |
| Font atlas | `lic/packages/li-ui/src/font_atlas.li`, `font_atlas_data.li` | Metrics, SDF/bitmap paths |
| Typography API | `lic/packages/li-ui/src/lib.li` | `studio_typography_*`, `text_layout_*` (new) |
| PaintCmd | `lic/packages/li-ui/src/lib.li`, `paint_cmds_ext.li` | `paint_op_layer_blur`, alpha-aware fills |
| Raster | `lic/runtime/` or `studio/deploy/studio-demo/native/` blit | Source-over + blur kernel |
| Motion | `lic/packages/li-gui/src/motion.li` (new) | Easing, tween, clock |
| Studio FX | `studio/src/lib.li` | Shadow/diffusion/opacity paint helpers |
| Studio motion | `studio/src/lib.li` | Panel/hover transition application |
| Smokes | `lic/packages/li-ui/li-tests/smoke/`, `studio/li-tests/smoke/` | Per-WP proof gates |
| Manifest | `data/world-studio-typography-fx-animation-loop/latest-screenshots.json` | Acceptance PNG list |

---

## P0 — Typography engine (W0, W1)

### Problem

Product-visual shipped **bitmap atlas + draw_glyphs**, but tests are thin (token constants, one glyph smoke). Agents cannot safely refactor metrics without a **lit test matrix**.

### W0 — Typography tests (`wtfx-w0-typography-tests`)

**Deliverables**

- [ ] New module `lic/packages/li-ui/src/text_layout.li` (mirrored into `lib.li`):
  - `text_metrics_line_height_px(face, size_px) -> float`
  - `text_metrics_advance_run_px(face, first_cp, count) -> float`
  - `text_truncate_to_width_px(...)` (ellipsis policy documented)
- [ ] Expand smokes:
  - `li-tests/smoke/font_atlas_metrics_matrix.li` — all printable ASCII: advance > 0, ink consistency
  - `li-tests/smoke/text_layout_baseline.li` — line height ≥ body_px, mono vs ui family
  - `li-tests/smoke/studio_typography_tokens.li` — keep; add caption_px assert if token adds it
- [ ] `studio/li-tests/smoke/studio_typography_engine.li` — compose shell regions emit `draw_glyphs` with bounds inside layout rects
- [ ] Register smokes in `li-ui/li-tests/manifest.toml` and `studio/li-tests/manifest.toml`

**Proof gate**

```bash
lic check --paths packages/li-ui/li-tests/smoke/font_atlas_metrics_matrix.li
lic check --paths packages/li-ui/li-tests/smoke/text_layout_baseline.li
lic check --paths studio/li-tests/smoke/studio_typography_engine.li
```

**Done when:** All three smokes exit 0; `font_atlas_version` bumped if atlas layout changes.

### W1 — Typography raster (`wtfx-w1-typography-raster`)

**Deliverables**

- [ ] `paint_cmd_draw_glyphs_run` records **used width/height** in `PaintCmd` ext fields (or companion `GlyphRunLayout` struct)
- [ ] `studio_paint_*` chrome uses `text_metrics_*` for label centering (dock, topbar, inspector headers)
- [ ] Smoke: `studio/li-tests/smoke/studio_typography_raster_bounds.li` — glyph cmds stay inside parent `Rect` ± 1px epsilon

**Done when:** No label paint proc uses ad-hoc `label_chars * 7.0` without `font_atlas_glyph_advance_px`.

---

## P1 — Opacity & compositing (W2)

### W2 — Opacity (`wtfx-w2-opacity-compositing`)

**Tokens** (`[fx]` in TOML):

```toml
[fx]
opacity_disabled = 0.38
opacity_scrim = 0.55
opacity_hover_delta = 0.08
```

**Deliverables**

- [ ] `color_with_alpha(c: Color, alpha: float) -> Color` with `requires 0.0 <= alpha <= 1.0`
- [ ] `color_over(dst, src) -> Color` — source-over in linear or documented gamma space (pick one; document in RFC stub)
- [ ] Raster path: `paint_blit` (or Li raster proc) respects `Color.a` for fill_round, fill_rect, draw_glyphs
- [ ] `paint_cmd_fill_round` / gradients accept alpha < 1 without premultiply bugs
- [ ] Smokes:
  - `li-ui/li-tests/smoke/color_alpha_composite.li` — pure math cases (0, 0.5, 1)
  - `studio/li-tests/smoke/studio_viewport_scrim_opacity.li` — overlay uses `opacity_scrim`

**Done when:** Viewport menu scrim alpha matches token; smoke proves composite of two known colors.

---

## P2 — Shadows & diffusion (W3, W4)

### W3 — Shadow math (`wtfx-w3-shadow-math`)

**Baseline:** `studio_paint_panel_shadow_*` exists (offset layers, alpha falloff). Generalize:

**Deliverables**

- [ ] `studio_shadow_params(depth: int) -> ShadowParams` struct: `layer_count`, `offset_base_px`, `spread_px`, `alpha_base`, `alpha_falloff`, `rgb`
- [ ] Pure functions:
  - `shadow_layer_offset_px(params, layer, depth) -> float`
  - `shadow_layer_alpha(params, layer) -> float`
  - `shadow_layer_rect(panel, params, layer, depth) -> Rect`
- [ ] Refactor `studio_paint_panel_shadow_at_depth` to call pure helpers only
- [ ] Smokes:
  - `studio/li-tests/smoke/studio_shadow_math.li` — monotonic offset; alpha strictly decreasing per layer
  - Keep `studio_polish_w4_shadows_spacing.li` green (cmd counts may shift — update documented bounds)

### W4 — Diffusion / blur (`wtfx-w4-diffusion-blur`)

**Tokens:**

```toml
[fx]
blur_sigma_px = 3.0
blur_radius_px = 6.0
blur_passes = 2
```

**Deliverables**

- [ ] `paint_op_layer_blur` (or `paint_op_blur_rect`) in PaintCmd IR
- [ ] `blur_separable_box` or `blur_gaussian_approx` on **alpha mask** of shadow layers (not full framebuffer first — bounded cost)
- [ ] `studio_paint_panel_shadow_diffused` — layers × blur; cmd count upper bound in smoke
- [ ] Smoke: `li-ui/li-tests/smoke/blur_kernel_energy.li` — kernel weights sum to 1.0 ± ε
- [ ] Smoke: `studio/li-tests/smoke/studio_shadow_diffusion.li` — elevated panel cmd count > flat shadow-only

**Done when:** `[elevation]` tokens drive blur sigma; changing `blur_sigma_px` in TOML changes smoke-observable spread (snapshot or cmd metadata).

---

## P3 — Motion core (W5)

### W5 — Motion core (`wtfx-w5-motion-core`)

**Tokens:**

```toml
[motion]
panel_transition_ms = 100
hover_transition_ms = 200

[animation]
easing_default = "ease_out_cubic"
reduced_motion_scale = 0.0
```

**Deliverables**

- [ ] `lic/packages/li-gui/src/motion.li`:
  - `easing_linear(t)`, `easing_ease_out_cubic(t)`, `easing_ease_in_out_cubic(t)` for `t in [0,1]`
  - `tween_float(from, to, t, easing_id) -> float`
  - `motion_clock_ms(frame_id, dt_ms) -> float` (monotonic)
- [ ] `motion_reduced() -> int` stub (future OS pref; default 0)
- [ ] Smokes: `li-gui/li-tests/smoke/motion_easing.li` — boundary values `t=0 -> from`, `t=1 -> to`
- [ ] Contracts on all easing: `requires t >= 0.0`, `requires t <= 1.0`

**Done when:** No Studio transition uses linear `if step` without easing helper.

---

## P4 — Shell transitions (W6)

### W6 — Shell transitions (`wtfx-w6-shell-transitions`)

**Deliverables**

- [ ] `StudioMotionState` on `StudioShellCompose` (or reactive store): `panel_t`, `hover_t`, `overlay_t`
- [ ] `studio_motion_tick(compose, dt_ms)` — advances tweens; clamps to 1.0
- [ ] Wire:
  - Panel switch ≤ `studio_panel_transition_ms()` (existing PH-UX budget)
  - Hover chip fade uses `opacity_hover_delta` × eased `hover_t`
  - Palette overlay scrim fades with `overlay_t`
- [ ] `motion_reduced() == 1` → snap to end state (no interpolation)
- [ ] Smokes:
  - `studio/li-tests/smoke/studio_panel_switch_timing.li` (extend)
  - `studio/li-tests/smoke/studio_motion_hover_opacity.li` — mid-tween alpha between base and target

**Done when:** `gui_panel_switch_to` path calls motion tick; paint uses interpolated colors.

---

## P5 — Acceptance (W7)

### W7 — Acceptance (`wtfx-w7-acceptance`)

**Screenshots** (native Li raster, under `docs/demo/media/native-verticals/png/`):

| File | Shows |
|------|--------|
| `typography-fx-game-1280x720.png` | Full shell: text + shadow + hover transition frame |
| `typography-fx-game.png` | Same at 640×360 |
| `typography-fx-inspector-panel.png` | Inspector: field labels + elevated card + blur shadow |
| `typography-fx-palette-overlay.png` | Palette open: scrim opacity + diffusion |

**Deliverables**

- [ ] Update `data/world-studio-typography-fx-animation-loop/latest-screenshots.json`
- [ ] `latest-iteration-assessment.json` per iteration
- [ ] Completion gate passes; all `wtfx-w*` YAML `done`
- [ ] `lic build` green for `studio` + `li-ui` + `li-gui` smoke packages

---

## Iteration checklist (agent)

1. `git checkout cursor/world-studio-typography-fx-animation` (studio + lic)
2. Pick lowest pending `wtfx-w*` (P0 first).
3. Implement in **native Li** only.
4. Run `./scripts/world-studio-typography-fx-animation-gates.sh`
5. Capture screenshots (best-effort on K8s; required on dev machine with raster).
6. Update phase table + YAML todo `done`.
7. Commit with message prefix `feat(studio): wtfx-wN ...`
8. Push; let K8s worker sync or run deploy script locally.

---

## Out of scope (defer)

- MCP `ui_snapshot` / per-element agent IDs (separate sprint)
- wgpu UI pass execution of blur (CPU first)
- Real TTF/SDF rebuild pipeline (optional spike after W1 if bitmap insufficient)
- `@cursor/sdk` cloud wiring

---

## K8s handoff

Homelab worker: `li-world-studio-typography-fx-animation` in `li-cursor-agents`:

```powershell
cd li-cursor-agents
.\scripts\deploy-world-studio-typography-fx-animation-k8s.ps1
```

Scale to 1 to start; worker scales to 0 when completion gate passes (`LI_GOAL_SCALE_DOWN_ON_COMPLETE=1`).
