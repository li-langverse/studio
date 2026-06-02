# World Studio native GUI polish (W0–W2)

**Plan:** [World Studio GUI library plan (W0–W5)](https://github.com/li-langverse/studio/pull/18) · loop [`2026-05-31-world-studio-gui-polish-loop.md`](../superpowers/plans/2026-05-31-world-studio-gui-polish-loop.md)  
**PR:** [`studio#19`](https://github.com/li-langverse/studio/pull/19)  
**PH / WP:** PH-UX · WP-UX-02, WP-UX-06, GUI-LIBRARY-PLAN Phase 2

## W0 — Typography on shell chrome

- Body/caption line heights from design tokens (`studio_typography_*`).
- Outliner rows, dock caption, topbar profile chip, and empty inspector hints use `studio_paint_glyph_text` (not placeholder rects).
- Smoke: `li-tests/smoke/studio_polish_w0_typography.li`.

## W1 — Glyph pipeline

- Dock slot icons from atlas; viewport HUD chips; inspector field label/value glyphs (drug LITL pilot).
- `studio_paint_glyph_pipeline_ok` gate; `li_std_studio_version` → 40.
- Smoke: `li-tests/smoke/studio_polish_w1_glyphs.li`.

## W2 — Hover, focus, shortcut hints

- `studio_shell_sync_hover` drives dock/outliner/timeline hover fills and playhead ring.
- Panel focus ring in `studio_paint_shell_chrome`.
- Topbar palette shortcut hints (closed) + per-row digit/label hints (open).
- `li_std_studio_version` → 42; smokes `studio_polish_w2_{hover,focus_ring,shortcut_hints}.li`.

## Proof / CI

- `lic check packages/li-studio/src/lib.li` (studio CI `check` job).
- `./scripts/world-studio-gui-polish-gates.sh` (token verify + screenshot manifest).

## north_star_fit

Product UX (gaming/tools) · proof-first paint contracts before perf polish · bench N/A for chrome-only wave.
