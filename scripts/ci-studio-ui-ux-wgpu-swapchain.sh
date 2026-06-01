#!/usr/bin/env bash
# CI gate: wgpu swapchain readback hook (studio-ux-19).
# CPU runners: expect status=blocked_runner (honest). GPU runners: set LIG_WGPU_SWAPCHAIN=1.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export STUDIO_UI_UX_GATES_SKIP_BUILD=1
export LI_REPO_ROOT="$ROOT"
export LIG_WGPU_SWAPCHAIN="${LIG_WGPU_SWAPCHAIN:-1}"

chmod +x scripts/bench-studio-viewport-perf.sh 2>/dev/null || true
./scripts/bench-studio-viewport-perf.sh

python3 "$ROOT/scripts/studio-ui-ux-verify-wgpu-swapchain.py"
