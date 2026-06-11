#!/usr/bin/env bash
# Resolve AIMD batch env: steps + dft_stride from scenario JSON, REAL_AIMD override.
set -euo pipefail

studio_aimd_resolve_from_scenario() {
  local scenario="${1:?scenario path required}"
  python3 - "$scenario" <<'PY'
import json, os, sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
steps = int(data.get("steps", 5000))
stride = int(data.get("dft_stride", 50))
if os.environ.get("REAL_AIMD", "") == "1":
    stride = 1
elif os.environ.get("STUDIO_AIMD_DFT_STRIDE", ""):
    stride = int(os.environ["STUDIO_AIMD_DFT_STRIDE"])
if stride < 1:
    stride = 1
print(steps)
print(stride)
PY
}

studio_aimd_export_batch_env() {
  local scenario="${1:?scenario path required}"
  local lines
  lines="$(studio_aimd_resolve_from_scenario "$scenario")"
  export STUDIO_AIMD_BATCH_STEPS="$(echo "$lines" | sed -n '1p')"
  export STUDIO_AIMD_DFT_STRIDE="$(echo "$lines" | sed -n '2p')"
  export STUDIO_AIMD_PILOT="${STUDIO_AIMD_PILOT:-1}"
}

studio_aimd_expected_dft_calls() {
  local steps="$1"
  local stride="$2"
  python3 - "$steps" "$stride" <<'PY'
import sys
steps = int(sys.argv[1])
stride = max(1, int(sys.argv[2]))
calls = sum(1 for md_step in range(steps) if md_step % stride == 0)
if stride > 1 and steps > 0 and steps % stride == 0:
    calls += 1
print(calls)
PY
}

# STUDIO_AIMD_GPU=1 — enable honest gpu_path via chem_dft_gpu_path_available() (LKIR scaffold).
# Unset or 0 keeps dev/CI CPU stub (gpu_path=0) for fast gates.
studio_aimd_gpu_env_note() {
  if [[ "${STUDIO_AIMD_GPU:-0}" == "1" ]]; then
    echo "studio-aimd: STUDIO_AIMD_GPU=1 — batch will report gpu_path when LKIR path available"
  fi
}
