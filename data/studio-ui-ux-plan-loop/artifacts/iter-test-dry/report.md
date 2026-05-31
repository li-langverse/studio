## Studio UI/UX iteration `test-dry`

- **UTC:** 2026-05-24T13:14:00Z
- **Branch:** cursor/httpd-plan-continue

### Bench snapshot
```json
{
  "generated_at": "2026-05-24T13:14:00Z",
  "load_ms": 0.04,
  "viewport_fps_target": 60,
  "panel_switch_ms_target": 100,
  "particle_tiers": [
    {
      "id": "md_1k",
      "particles": 1000,
      "fps_target": 60,
      "status": "fail",
      "bench_exit": 2,
      "stderr_tail": "usage: bench.py [-h] [--tier TIER] [--sample] [--ci] [--runs RUNS]\n                [--skip-verify] [--verify-results] [--out OUT] [--only ONLY]\n                [--package PACKAGE] [--changed]\nbench.py: error: unrecognized arguments: --filter md_lennard_jones\n"
    },
    {
      "id": "md_10k",
      "particles": 10000,
      "fps_target": 60,
      "status": "fail",
      "bench_exit": 2,
      "stderr_tail": "usage: bench.py [-h] [--tier TIER] [--sample] [--ci] [--runs RUNS]\n                [--skip-verify] [--verify-results] [--out OUT] [--only ONLY]\n                [--package PACKAGE] [--changed]\nbench.py: error: unrecognized arguments: --filter md_lennard_jones\n"
    },
    {
      "id": "md_100k",
      "particles": 100000,
      "fps_target": 30,
      "status": "fail",
      "bench_exit": 2,
      "stderr_tail": "usage: bench.py [-h] [--tier TIER] [--sample] [--ci] [--runs RUNS]\n                [--skip-verify] [--verify-results] [--out OUT] [--only ONLY]\n                [--package PACKAGE] [--changed]\nbench.py: error: unrecognized arguments: --filter md_lennard_jones\n"
    }
  ],
  "memory_mib": {
    "profile_exit": 0,
    "lines": [
      "tracemalloc peak (import): 1.07 MiB"
    ]
  },
  "notes": []
}
```

### Artifacts
- PNG count: 1
- Video: `iter-reel.mp4` (GitHub release only)

Rubric: `docs/game-dev/competitive-intel/ui-ux-by-dimension.md`
