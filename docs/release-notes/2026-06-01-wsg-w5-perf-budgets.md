# World Studio GUI Phase 5 — viewport and UI performance budgets

## Summary

Documents **PH-UX performance gates** for installer-ready native Li World Studio (GUI library plan Phase 5, `wsg-w5-perf-budgets`). Budgets are canonical in `docs/design/studio-design-tokens.toml` (`[ph_ux]`), mirrored in `benchmarks/competitive/studio-ui.toml`, and verified by `./scripts/bench-studio-viewport-perf.sh` plus `studio_perf_budgets_smoke`.

## Performance budgets

| Gate | Target | Unit | Measure / smoke |
|------|--------|------|-----------------|
| Viewport FPS | ≥ 60 | fps | `render_viewport_fps_target()`, `bench-studio-viewport-perf.sh` → `gates.viewport_fps` |
| Panel switch | ≤ 100 | ms | `gui_panel_switch_budget_ms()`, `studio_panel_switch_*`, `gates.panel_switch_ms` |
| Cold studio load | ≤ 2000 | ms | `bench-studio-viewport-perf.sh` → `gates.studio_load_ms` / `load_ms` |
| MD 1k particles | ≥ 60 | fps | `gates.md_1k` — tier-1 scientific viewport |
| MD 10k particles | ≥ 60 | fps | `gates.md_10k` — default scientific HUD tier |
| MD 100k particles | ≥ 30 | fps | `gates.md_100k` — workstation tier (refuse over-budget in compose) |
| animate_md import memory | ≤ 512 | MiB warn | `gates.animate_md_import`, `profile-animate-memory.sh` |

### UI interaction micro-budgets (native chrome)

| Journey | Target | Unit | Verify script |
|---------|--------|------|---------------|
| Command palette open | ≤ 50 | ms | `studio-ui-ux-verify-palette-native.py` |
| Command palette filter | ≤ 30 | ms | `studio-ui-ux-verify-palette-native.py` |
| Keyboard tab focus step | ≤ 16 | ms | `studio-ui-ux-verify-keyboard-journey.py` |
| Keyboard shortcut step | ≤ 16 | ms | `studio-ui-ux-verify-keyboard-journey.py` |
| Agent chrome tick | ≤ 16 | ms | `studio-ui-ux-verify-agent-chrome-native.py` |
| Agent cancel | ≤ 16 | ms | `studio-ui-ux-verify-agent-chrome-native.py` |

### Motion tokens (design, not hard CI gate)

| Token | Value | Source |
|-------|-------|--------|
| Panel transition | 100 ms | `studio-design-tokens.toml` `[motion].panel_transition_ms` |
| Hover transition | 200 ms | `[motion].hover_transition_ms` |

## Release hardware expectations

Budgets assume **1080p shell** (1280×720 minimum demo) on a 2024-class laptop or CI runner with software raster fallback. **Native wgpu** paths (`LIG_WGPU_SWAPCHAIN=1`, Windows/macOS/Linux installers) must meet viewport FPS on discrete or integrated GPU when `LIG_HOST_PRESENT=1`. Honest simulate mode (`gates.*.honest_simulate`) is acceptable in agent/CI sandboxes without GPU; product installers target real hardware.

## How to verify

```bash
cd studio
./scripts/bench-studio-viewport-perf.sh
python3 scripts/verify-perf-budgets.py
# optional full UX registry when memory profile present:
# python3 scripts/studio-ui-ux-verify-bench-registry.py
```

Latest bench JSON: `data/studio-ui-ux-plan-loop/latest-bench.json`  
Competitive export: `benchmarks/results/bench-studio-viewport-perf.json`

## Li API (native)

- `studio_perf_budgets_version()` — schema version for Phase 5 perf docs
- `studio_viewport_fps_budget()`, `studio_panel_switch_ms_budget()`, `studio_load_ms_budget()`, `studio_memory_warn_peak_mib_budget()` — constants aligned with tokens/registry
- `studio_perf_budgets_smoke()` — cross-checks `render_viewport_fps_target()` and `gui_panel_switch_budget_ms()`

Smoke: `li-tests/smoke/studio_perf_budgets.li`

## Breaking

None — documentation + registry v2 + smoke constants only.

## Security

N/A — no new FFI or trusted surface.

## Downstream

Installer README links here. CI matrix (`world-studio-installers.yml`) runs source verify; live GPU benches run on release hardware or nightly when hooks are available.
