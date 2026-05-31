## Studio UI/UX iteration `wsg-w1-event-dispatcher`

- **UTC:** 2026-05-31T18:51:59Z
- **Branch:** cursor/world-studio-gui-library-plan

### Bench snapshot
```json
{
  "generated_at": "2026-05-31T18:51:59Z",
  "registry_path": "benchmarks\\competitive\\studio-ui.toml",
  "registry_schema": "li_studio_ui_bench_v1",
  "registry_version": 0,
  "load_ms": 0.56,
  "viewport_fps_target": 60,
  "panel_switch_ms_target": 100,
  "studio_load_ms_target": 2000,
  "viewport_fps": {},
  "panel_switch_ms": {},
  "particle_tiers": [
    {
      "id": "md_1k",
      "particles": 1000,
      "fps_target": 60,
      "status": "skip"
    },
    {
      "id": "md_10k",
      "particles": 10000,
      "fps_target": 60,
      "status": "skip"
    },
    {
      "id": "md_100k",
      "particles": 100000,
      "fps_target": 30,
      "status": "skip"
    }
  ],
  "memory_mib": {
    "profile": {
      "schema": "li_studio_memory_profile_v1",
      "generated_at": "2026-05-30T22:06:48Z",
      "memory_id": "animate_md_import",
      "warn_peak_mib": 512.0,
      "peak_import_mib": 0.56,
      "peak_rss_mib": null,
      "peak_observed_mib": 0.56,
      "meets_budget": true,
      "rss_status": "skip",
      "registry_path": "benchmarks\\competitive\\studio-ui.toml",
      "notes": [
        "import peak = tracemalloc after loading animate_md",
        "rss peak = --skip-export --max-frames 4 when /usr/bin/time available",
        "full GIF export can exceed budget; Studio timeline uses streamed frames"
      ]
    },
    "warn_peak_mib": 512.0,
    "peak_observed_mib": 0.56,
    "meets_budget": true
  },
  "gates": {
    "viewport_fps": {
      "target": 60,
      "value": null,
      "unit": "fps",
      "meets_target": false,
      "honest_simulate": false
    },
    "panel_switch_ms": {
      "target": 100,
      "value": null,
      "unit": "ms",
      "meets_target": false,
      "honest_simulate": false
    },
    "studio_load_ms": {
      "target": 2000,
      "value": 0.56,
      "unit": "ms",
      "meets_target": true,
      "honest_simulate": true
    },
    "md_1k": {
      "target": 60,
      "value": null,
      "unit": "fps",
      "particles": 1000,
      "meets_target": false,
      "honest_simulate": false
    },
    "md_10k": {
      "target": 60,
      "value": null,
      "unit": "fps",
      "particles": 10000,
      "meets_target": false,
      "honest_simulate": false
    },
    "md_100k": {
      "target": 30,
      "value": null,
      "unit": "fps",
      "particles": 100000,
      "meets_target": false,
      "honest_simulate": false
    },
    "animate_md_import": {
      "target": 512.0,
      "value": 0.56,
      "unit": "mib",
      "meets_target": true,
      "honest_simulate": true,
      "peak_import_mib": 0.56,
      "peak_rss_mib": null
    }
  },
  "hooks": {},
  "notes": [
    "skip_viewport_fps:li-render_missing",
    "studio_vertical_present:simulate",
    "skip_panel_switch:hook_missing",
    "skip_md_bench:lic_or_harness_missing"
  ],
  "studio_vertical_present": {
    "profile_count": 7,
    "bench_simulate_fn": "studio_vertical_demo_frame",
    "hook_version": 3,
    "native_pixels_paint_blit": false,
    "native_pixels_wgpu": false,
    "wgpu_full_readback": false,
    "status": "simulate",
    "honest_simulate": true,
    "env_host_present": "LIG_HOST_PRESENT",
    "env_wgpu_readback": "LIG_WGPU_READBACK",
    "notes": "LIG_HOST_PRESENT=1 + optional LIG_WGPU_READBACK=1: draw-list submit then blit/readback; honest sources 2|3|4"
  },
  "gates_pass": true
}
```

### Artifacts
- PNG count: 0

Rubric: `docs/game-dev/competitive-intel/ui-ux-by-dimension.md`
