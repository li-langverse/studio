## Studio UI/UX iteration `wsm-w6-publish-data`

- **UTC:** 2026-05-30T12:11:03Z
- **Branch:** cursor/world-studio-master-plan-loop

### Bench snapshot
```json
{
  "generated_at": "2026-05-30T12:11:03Z",
  "registry_path": "benchmarks\\competitive\\studio-ui.toml",
  "registry_schema": "li_studio_ui_bench_v1",
  "registry_version": 1,
  "load_ms": 0.32,
  "viewport_fps_target": 60,
  "panel_switch_ms_target": 100,
  "studio_load_ms_target": 2000,
  "viewport_fps": {
    "fps_target": 60,
    "fps_estimated": 60.0,
    "meets_target": true,
    "native_pixels": false,
    "native_pixels_stub": false,
    "wgpu_smoke_status": "draw_list",
    "wgpu_surface_ok": false,
    "wgpu_surface_ok_stub": false,
    "native_pixel_source": 0,
    "native_pixel_source_paint_blit": 2,
    "fps_counter_hook": "li-render",
    "bench_simulate_fn": "render_bench_fps_counter_simulate",
    "host_bench_fn": "render_viewport_host_fps_counter",
    "hook_version": 2,
    "status": "simulate",
    "honest_simulate": true
  },
  "panel_switch_ms": {
    "budget_ms": 100.0,
    "worst_elapsed_ms": 150.0,
    "median_elapsed_ms": 88.0,
    "transition_count": 3,
    "all_within_budget": false,
    "meets_target": false,
    "native_pixels": false,
    "status": "simulate",
    "bench_simulate_fn": "gui_panel_switch_budget_ms"
  },
  "particle_tiers": [
    {
      "id": "md_1k",
      "tier_id": 0,
      "particles": 1000,
      "fps_target": 60,
      "fps_estimated": 60.0,
      "meets_target": true,
      "status": "simulate",
      "native_pixels": false,
      "draw_path": "scene_budget_simulate",
      "kernel": "md_lennard_jones",
      "hook_version": 1,
      "bench_simulate_fn": "scene_bench_particle_tier_simulate"
    },
    {
      "id": "md_10k",
      "tier_id": 1,
      "particles": 10000,
      "fps_target": 60,
      "fps_estimated": 60.0,
      "meets_target": true,
      "status": "simulate",
      "native_pixels": false,
      "draw_path": "scene_budget_simulate",
      "kernel": "md_lennard_jones",
      "hook_version": 1,
      "bench_simulate_fn": "scene_bench_particle_tier_simulate"
    },
    {
      "id": "md_100k",
      "tier_id": 2,
      "particles": 100000,
      "fps_target": 30,
      "fps_estimated": 30.0,
      "meets_target": true,
      "status": "simulate",
      "native_pixels": false,
      "draw_path": "scene_budget_simulate",
      "kernel": "md_lennard_jones",
      "hook_version": 1,
      "bench_simulate_fn": "scene_bench_particle_tier_simulate"
    }
  ],
  "memory_mib": {
    "profile_exit": 1,
    "lines": [
      "tracemalloc peak (import): 0.56 MiB",
      "==> budget warn_peak_mib=512 observed=0.56 meets=True",
      "STUDIO_MEMORY_JSON={\"schema\":\"li_studio_memory_profile_v1\",\"generated_at\":\"2026-05-30T12:11:03Z\",\"memory_id\":\"animate_md_import\",\"warn_peak_mib\":512.0,\"peak_import_mib\":0.56,\"peak_rss_mib\":null,\"peak_observed_mib\":0.56,\"meets_budget\":true,\"rss_status\":\"skip\",\"registry_path\":\"benchmarks\\\\competitive\\\\studio-ui.toml\",\"notes\":[\"import peak = tracemalloc after loading animate_md\",\"rss peak = --skip-export --max-frames 4 when /usr/bin/time available\",\"full GIF export can exceed budget; Studio timeline uses streamed frames\"]}"
    ],
    "profile": {
      "schema": "li_studio_memory_profile_v1",
      "generated_at": "2026-05-30T12:11:03Z",
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
      "```

### Artifacts
- PNG count: 27

Rubric: `docs/game-dev/competitive-intel/ui-ux-by-dimension.md`
