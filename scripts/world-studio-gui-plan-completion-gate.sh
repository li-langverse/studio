#!/usr/bin/env bash
# Exit 0 only when all wsg-w* plan todos are done, gates pass, and Phase 0 styled chrome minimum met.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"
PLAN="$ROOT/docs/superpowers/plans/2026-05-31-world-studio-gui-library-plan-loop.md"
ASSESS="$ROOT/data/world-studio-gui-plan-loop/latest-iteration-assessment.json"
LI_UI="$LIC_ROOT/packages/li-ui/src/lib.li"

if [[ ! -f "$PLAN" ]]; then
  echo "world-studio-gui completion gate: missing plan $PLAN" >&2
  exit 1
fi

if ! python3 - "$PLAN" <<'PY'
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8")
pending = []
for m in re.finditer(
    r"- id: (wsg-w\S+)\n\s+content: [^\n]+\n\s+status: (\w+)", text
):
    if m.group(2) != "done":
        pending.append(m.group(1))
if pending:
    print("world-studio-gui completion gate: pending todos:", ", ".join(pending), file=sys.stderr)
    sys.exit(1)
PY
then
  exit 1
fi

"$ROOT/scripts/world-studio-gui-plan-gates.sh"

# Phase 0 minimum: native window must not be wireframe-only.
styled=0
if [[ -f "$ASSESS" ]]; then
  ASSESS_PATH="$ASSESS" python3 -c "
import json, os, sys
from pathlib import Path
p = Path(os.environ['ASSESS_PATH'])
d = json.loads(p.read_text(encoding='utf-8'))
sys.exit(0 if d.get('styled_chrome_minimum') or d.get('phase0_styled_chrome') else 1)
" && styled=1 || true
fi
if [[ "$styled" == "0" ]] && [[ -f "$LI_UI" ]]; then
  if grep -qE 'fill_round_rect|stroke_round_rect|paint_op_fill_round' "$LI_UI"; then
    styled=1
  fi
fi
if [[ "$styled" == "0" ]]; then
  echo "world-studio-gui completion gate: Phase 0 styled chrome not verified (wireframe-only still)" >&2
  echo "  set styled_chrome_minimum: true in $ASSESS or land wsg-w0-* paint ops" >&2
  exit 1
fi

echo "world-studio-gui completion gate: all wsg-w* todos done + styled chrome minimum"
