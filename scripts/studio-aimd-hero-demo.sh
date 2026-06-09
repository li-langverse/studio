#!/usr/bin/env bash
# Hero demo orchestrator (W5): configure → batch run → final frame capture + trace manifest.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export STUDIO_ROOT="$ROOT"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"

DEMO_JSON="$STUDIO_ROOT/data/demo-scripts/aimd-hero.demo.json"
SCENARIO="$STUDIO_ROOT/data/world-studio-aimd-demo-loop/hero-scenario.json"
OUT_DIR="$STUDIO_ROOT/build/aimd-demo/out"
TRACE="$STUDIO_ROOT/data/world-studio-aimd-demo-loop/latest-demo-trace.json"
E2E_SMOKE="packages/li-studio/li-tests/smoke/studio_aimd_hero_e2e.li"

[[ -f "$DEMO_JSON" ]] || { echo "studio-aimd-hero-demo: missing $DEMO_JSON" >&2; exit 1; }
[[ -f "$SCENARIO" ]] || { echo "studio-aimd-hero-demo: missing $SCENARIO" >&2; exit 1; }
mkdir -p "$OUT_DIR"

LIC_BIN="$(resolve_lic 2>/dev/null || true)"
[[ -n "$LIC_BIN" && -x "$LIC_BIN" ]] || { echo "studio-aimd-hero-demo: lic not found" >&2; exit 2; }

cp -f "$STUDIO_ROOT/src/lib.li" "$LIC_ROOT/packages/li-studio/src/lib.li" 2>/dev/null || true
for smoke in studio_aimd_hero_e2e.li studio_aimd_hero_runner.li studio_aimd_final_viz.li studio_mcp_aimd_configure.li; do
  if [[ -f "$STUDIO_ROOT/li-tests/smoke/$smoke" ]]; then
    cp -f "$STUDIO_ROOT/li-tests/smoke/$smoke" "$LIC_ROOT/packages/li-studio/li-tests/smoke/$smoke" 2>/dev/null || true
  fi
done

bash "$STUDIO_ROOT/scripts/studio-aimd-batch-run.sh" "$SCENARIO" "$OUT_DIR" || exit 3

(cd "$LIC_ROOT" && "$LIC_BIN" check "$E2E_SMOKE" --workspace=packages/li.toml) \
  || { echo "studio-aimd-hero-demo: studio_aimd_hero_e2e smoke failed" >&2; exit 4; }

python3 - "$DEMO_JSON" "$SCENARIO" "$OUT_DIR" "$TRACE" <<'PY'
import json, sys
from pathlib import Path

demo = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
scenario = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
out_dir = Path(sys.argv[3])
trace_path = Path(sys.argv[4])
final = out_dir / "final-frame.ppm"
batch_meta = out_dir / "batch-result.json"
meta = json.loads(batch_meta.read_text(encoding="utf-8")) if batch_meta.is_file() else {}
steps = int(meta.get("steps", scenario.get("steps", 5000)))
trace = {
    "native_only": True,
    "demo_script": demo.get("name"),
    "demo_script_path": "data/demo-scripts/aimd-hero.demo.json",
    "scenario": scenario.get("name"),
    "profile": scenario.get("profile"),
    "steps": steps,
    "checksum": meta.get("checksum"),
    "gpu_path": meta.get("gpu_path", 0),
    "tier": meta.get("tier", "stub"),
    "energy_drift": meta.get("energy_drift"),
    "batch_result": str(batch_meta.relative_to(out_dir.parent.parent)) if batch_meta.is_file() else None,
    "final_frame": str(final.relative_to(out_dir.parent.parent)) if final.is_file() else None,
    "configure_phase": "mcp_sim_scientific+aimd_configure_scenario",
    "batch_headless": True,
    "ui_step_replay": False,
}
trace_path.parent.mkdir(parents=True, exist_ok=True)
trace_path.write_text(json.dumps(trace, indent=2) + "\n", encoding="utf-8")
print("studio-aimd-hero-demo: trace written", trace_path)
if final.stat().st_size < 4096:
    raise SystemExit(f"final frame too small: {final}")
PY

echo "studio-aimd-hero-demo: OK"
