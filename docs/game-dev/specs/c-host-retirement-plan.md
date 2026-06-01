# C-host retirement plan (WP-UX-14b / WP-GD-05)

**Status:** IN_PROGRESS — steps 1–3 landed; step 4 partial (`wsg-w4-c-host-slim` slimmed present host; full deletion pending headless golden)  
**Policy:** Li-native product pixels only (`li-studio`, `li-render`, `lig.present`)

## Current C hosts (`deploy/studio-demo/native/`)

| File | Role | Li/wgpu replacement |
|------|------|---------------------|
| `studio_verticals_present_host.c` | CPU framebuffer per-vertical capture | `lig` wgpu present + `RenderReadPixels` readback; `li-studio-demo` swapchain |
| `studio_shell_present_host.c` | **I/O only** — SDL window/input/surface (`STUDIO_SHELL_HOST_IO_ONLY`) | `li-studio-demo` + `studio_shell_present_raster_and_blit` |
| `studio_viewport_capture.c` | SDL grid/particle viewport capture stub | `li-render` wgpu viewport smoke + tier-2 sim particles in Li |
| `studio_shell_input_probe.c` | Input probe for shell demos | `InputState` via Li runtime poll or `lig` window queue |
| `studio_shell_paint_fb.c` | paint_blit framebuffer mirror (fenced) | `li-render` UI raster pass (Li path) |

## Retirement steps

| Step | Deliverable | Replaces | Status |
|------|-------------|----------|--------|
| 1 | `lig` wgpu present + `RenderReadPixels` readback | `studio_viewport_capture.c` grid path | done |
| 2 | `li-render` blit paint summary → swapchain | `studio_shell_paint_fb.c` product path | done |
| 3 | `InputState` from Li poll / `lig` events | `studio_shell_input_probe.c` product path | done |
| 4 | Delete C paint/present hosts; update capture scripts | all rows above | **partial** — present host slimmed; paint_fb fenced for CI golden |

## Scope fence (grandfathered until Step 4 complete)

Do not extend with new product features:

- `studio_verticals_present_host.c`
- `studio_shell_present_host.c` (I/O only — no paint)
- `studio_viewport_capture.c`
- `studio_shell_input_probe.c`
- `studio_shell_paint_fb.c` (CI mirror only)

New pixel paths: `packages/li-studio` + `packages/li-render` + `lig.present` only.

## Verification

```bash
./scripts/studio-c-host-retirement-gate.sh
./scripts/world-studio-gui-plan-gates.sh
lic check li-tests/smoke/studio_c_host_slim.li
LIG_HOST_PRESENT=1 ./deploy/studio-demo/native/studio_shell_present_host --width 1280 --height 720
```

Exit: no product C paint under present host; `studio_shell_paint_fb.c` deleted only after `wsg-w4-headless-golden`.
