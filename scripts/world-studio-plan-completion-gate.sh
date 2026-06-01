#!/usr/bin/env bash
# Exit 0 only when all wsm-w* plan todos are done and iteration gates pass.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLAN="$ROOT/docs/superpowers/plans/2026-05-29-world-studio-master-plan-loop.md"

if [[ ! -f "$PLAN" ]]; then
  echo "world-studio completion gate: missing plan $PLAN" >&2
  exit 1
fi

if ! python3 - "$PLAN" <<'PY'
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding="utf-8")
pending = []
for m in re.finditer(
    r"- id: (wsm-w\S+)\n\s+content: [^\n]+\n\s+status: (\w+)", text
):
    if m.group(2) != "done":
        pending.append(m.group(1))
if pending:
    print("world-studio completion gate: pending todos:", ", ".join(pending), file=sys.stderr)
    sys.exit(1)
PY
then
  exit 1
fi

"$ROOT/scripts/world-studio-plan-gates.sh"
echo "world-studio completion gate: all wsm-w* todos done"
