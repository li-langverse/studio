#!/usr/bin/env bash
# Progress gates for world-studio-typography-fx-animation (typography tests + FX + motion).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export STUDIO_ROOT="$ROOT"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }
ok() { echo "OK: $*"; }

PLAN_LOOP="$STUDIO_ROOT/docs/superpowers/plans/2026-06-03-world-studio-typography-fx-animation-loop.md"
GOAL="$STUDIO_ROOT/data/goal-directed-sprints/world-studio-typography-fx-animation.md"
TOKENS="$STUDIO_ROOT/docs/design/studio-design-tokens.toml"
STATE_DIR="$STUDIO_ROOT/data/world-studio-typography-fx-animation-loop"
PNG_DIR="$STUDIO_ROOT/docs/demo/media/native-verticals/png"

echo "==> typography-fx plan documents"
[[ -f "$PLAN_LOOP" ]] || fail "missing $PLAN_LOOP"
[[ -f "$GOAL" ]] || fail "missing $GOAL"
[[ -f "$TOKENS" ]] || fail "missing $TOKENS"
mkdir -p "$STATE_DIR" "$PNG_DIR"

echo "==> token verification"
if [[ -f "$STUDIO_ROOT/scripts/studio-ui-ux-verify-tokens.py" ]]; then
  export LIC_ROOT
  python3 "$STUDIO_ROOT/scripts/studio-ui-ux-verify-tokens.py" || fail "studio-ui-ux-verify-tokens"
else
  fail "missing studio-ui-ux-verify-tokens.py"
fi

resolve_lic_bin() {
  local c
  for c in \
    "$LIC_ROOT/build/compiler/lic/lic" \
    "$LIC_ROOT/out/compiler/lic/lic" \
    "$(command -v lic 2>/dev/null || true)"; do
    if [[ -n "$c" && -x "$c" ]]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

LIC_BIN=""
if LIC_BIN="$(resolve_lic_bin)"; then
  ok "lic=$LIC_BIN"
else
  warn "lic binary not found — skipping lit smokes (CI/K8s may still run agent code changes)"
fi

run_smoke() {
  local path="$1"
  if [[ -z "$LIC_BIN" ]]; then
    warn "skip smoke (no lic): $path"
    return 0
  fi
  if [[ ! -f "$path" ]]; then
    warn "smoke not yet added: $path"
    return 0
  fi
  echo "==> lic check $path"
  "$LIC_BIN" check --paths "$path" || fail "lic check $path"
}

# Baseline smokes (must stay green throughout sprint)
BASELINE_SMOKES=(
  "$LIC_ROOT/packages/li-ui/li-tests/smoke/studio_typography_tokens.li"
  "$LIC_ROOT/packages/li-ui/li-tests/smoke/font_atlas_inter_mono.li"
  "$STUDIO_ROOT/li-tests/smoke/studio_polish_w0_typography.li"
  "$STUDIO_ROOT/li-tests/smoke/studio_polish_w4_shadows_spacing.li"
)

for s in "${BASELINE_SMOKES[@]}"; do
  run_smoke "$s"
done

# W0+ smokes (warn until files land)
WTFX_SMOKES=(
  "$LIC_ROOT/packages/li-ui/li-tests/smoke/font_atlas_metrics_matrix.li"
  "$LIC_ROOT/packages/li-ui/li-tests/smoke/text_layout_baseline.li"
  "$STUDIO_ROOT/li-tests/smoke/studio_typography_engine.li"
  "$LIC_ROOT/packages/li-ui/li-tests/smoke/color_alpha_composite.li"
  "$STUDIO_ROOT/li-tests/smoke/studio_shadow_math.li"
  "$LIC_ROOT/packages/li-ui/li-tests/smoke/blur_kernel_energy.li"
  "$LIC_ROOT/packages/li-gui/li-tests/smoke/motion_easing.li"
  "$STUDIO_ROOT/li-tests/smoke/studio_motion_hover_opacity.li"
)

for s in "${WTFX_SMOKES[@]}"; do
  run_smoke "$s"
done

echo "==> plan YAML pending check (informational)"
python3 - "$PLAN_LOOP" <<'PY' || true
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8")
pending = []
matched = 0
for m in re.finditer(
    r"- id: (wtfx-w\S+)\n\s+content: [^\n]+\n\s+status: (\w+)", text
):
    matched += 1
    if m.group(2) != "done":
        pending.append(m.group(1))
if matched:
    print("pending wtfx todos:", ", ".join(pending) if pending else "(none)")
PY

ok "world-studio-typography-fx-animation progress gates finished"
