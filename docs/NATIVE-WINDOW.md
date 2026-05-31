# Native window path (Li World Studio)

## What was wrong

Screenshots looked like **marketing HTML mocks** (`deploy/studio-demo/screenshots/*.html`) or **headless C capture** (`studio-verticals-capture-native.sh` → `studio_shell_paint_fb.c` without SDL). Neither opens a real window tied to the Li present loop.

The old `studio_shell_present_host.c` drew a single cyan HUD rectangle in a **hidden** SDL window and exited — not full workspace chrome.

## Intended UI stack (today)

| Layer | Role |
|-------|------|
| **li-ui** | Shell composables: `layout_studio_shell_adaptive`, palette, regions |
| **li-gui** | Viewport region, keyboard routing, panel focus |
| **li-studio** / **studio** | `studio_compose_shell_*`, `studio_paint_shell_chrome` (PaintFrame IR) |
| **lig.present** | Host present bridge: swapchain stub, paint_blit honesty flags |
| **SDL present host** | Native window + CPU blit of shell layout (`studio_shell_paint_fb`) |

**wgpu viewport (WP-GD-05 / wsg-w3-wgpu-viewport-pixels):** `render_wgpu_viewport_readback` bridges `lig_wgpu_swapchain_readback_run` → `RenderViewportSmoke`; `native_pixels=1` when `LIG_WGPU_SWAPCHAIN=1` + `LIG_GPU_RUNNER=1` + `LIG_HOST_PRESENT=1`. CPU CI reports `blocked_runner` honestly; path B (CPU paint_blit) remains fallback.

## Real window launch (no installer)

```powershell
cd studio
.\scripts\start-li-world-studio-window.ps1 -Profile game
```

Options:

- `-Build` — build `li-studio-demo` first
- `-ScreenshotOnly` — write `installer/out/studio-screenshot-real-window.png` (no interactive window)
- `-SkipLiDemo` — open SDL window only

Equivalent:

```powershell
.\scripts\start-li-world-studio.ps1 -RealWindow -Profile game
```

Requires WSL + SDL2 (`sudo apt install libsdl2-dev`) and X11/WSLg for visible window.

## li-gui roadmap: Qt vs Svelte-like

**Do not rebuild Qt.** Apply patterns:

### Qt-inspired (li-gui widget tree)

- **Widget tree** with parent/child layout rects (already: `StudioShellCompose` + `layout_studio_shell_adaptive`)
- **Signals/slots** → typed `InputState` + `gui_handle_studio_key` / `studio_shell_handle_host_key` action enums
- **Paint via IR** → `PaintFrame` + `paint_op_fill_rect` (CPU today; wgpu draw-list later)

### Svelte-inspired (compile-time reactivity)

- **Composable stores** → `StudioShellCompose` fields updated per tick (`studio_vertical_demo_compose`)
- **Compile-time invalidation** → Li `requires`/`ensures` on compose/paint counts (smokes enforce chrome cmd counts)
- **No runtime VDOM** — layout computed in Li, not JS

**Recommendation:** extend **li-ui composables + li-gui input/viewport** first; add reactive store codegen when shell state grows (palette, agent FSM, timeline). wgpu path replaces paint_fb blit incrementally (WP-GD-05).

Full phased roadmap: [GUI-LIBRARY-PLAN.md](GUI-LIBRARY-PLAN.md).

## Honesty labels

| Source | `native_pixels` | Product? |
|--------|-----------------|----------|
| HTML mock | false | Marketing only |
| C paint_fb capture (no SDL) | true | CI / headless evidence |
| SDL present host (this path) | true | Real window; mirrors Li paint contracts |
| wgpu swapchain | true (when GPU runner env) | Production target (Path A) |