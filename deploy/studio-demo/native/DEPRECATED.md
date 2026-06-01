# Deprecated C capture hosts (WP-UX-14b)

**Status:** Fenced — do not extend. Product pixels are Li-native (`li-studio`, `li-render`, `lig.present`).

| File | Replacement |
|------|-------------|
| `studio_verticals_present_host.c` | `studio_vertical_demo_frame` + `LIG_WGPU_READBACK=1` |
| `studio_shell_present_host.c` | **I/O only** (`STUDIO_SHELL_HOST_IO_ONLY`) — Li `--rgb-ppm` blit; no paint mirror |
| `studio_shell_paint_fb.c` | `li-render` blit / wgpu draw list |
| `studio_viewport_capture.c` | `packages/li-render/li-tests/smoke/wgpu_draw_list.li` |
| `studio_shell_input_probe.c` | `studio_keyboard_bridge` / `InputState` smokes |

**Capture (preferred):**

```bash
STUDIO_VERTICALS_WGPU_READBACK=1 LIG_HOST_PRESENT=1 ./scripts/studio-verticals-capture-native.sh
lic check li-tests/smoke/studio_c_host_retirement_gate.li
```

Deletion tracked in [c-host-retirement-plan.md](../../../docs/game-dev/specs/c-host-retirement-plan.md) step 4.
