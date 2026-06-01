#!/usr/bin/env bash
# CI gate: wgpu readback bench hooks (studio-ux-18 wave-3 matrix leg).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export STUDIO_UI_UX_GATES_SKIP_BUILD=1
export LI_REPO_ROOT="$ROOT"
export LIG_WGPU_READBACK=1

chmod +x scripts/bench-studio-viewport-perf.sh 2>/dev/null || true
./scripts/bench-studio-viewport-perf.sh

python3 - <<'PY'
import json
import sys
from pathlib import Path

bench = json.loads(
    Path("data/studio-ui-ux-plan-loop/latest-bench.json").read_text(encoding="utf-8")
)
vf = bench.get("viewport_fps") or {}
wgpu_status = vf.get("wgpu_smoke_status", "")
surface_ok = bool(vf.get("wgpu_surface_ok", False))
native = bool(vf.get("native_pixels", False))

if wgpu_status not in ("readback_pass", "native", "draw_list", "paint_blit_host", "host_or_stub"):
    print(f"ci-studio-ui-ux-wgpu: unexpected wgpu_smoke_status={wgpu_status!r}", file=sys.stderr)
    sys.exit(1)
if not surface_ok and wgpu_status not in ("readback_pass", "host_or_stub"):
    print("ci-studio-ui-ux-wgpu: wgpu_surface_ok false", file=sys.stderr)
    sys.exit(1)

# Honest: compile-time readback smoke passes; swapchain pixels still SDL path unless LIG_HOST_PRESENT.
notes = bench.get("notes") or []
print(
    "ci-studio-ui-ux-wgpu: ok "
    f"wgpu_smoke_status={wgpu_status} surface_ok={surface_ok} native_pixels={native}"
)
if "present:li-gpu" not in notes:
    print("ci-studio-ui-ux-wgpu: warn li-gpu not in bench notes", file=sys.stderr)
PY
