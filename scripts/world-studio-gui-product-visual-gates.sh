#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "world-studio-gui-product-visual gates: start"

# 1) Plan YAML must parse and contain todos
python3 - <<'PY'
import re
from pathlib import Path

p = Path("docs/superpowers/plans/2026-06-02-world-studio-gui-product-visual-loop.md")
text = p.read_text(encoding="utf-8")
ids = re.findall(
    r"^- id: (wsv-\S+)\\s*\\r?\\n\\s+content: .*?\\r?\\n\\s+status: (\\w+)",
    text,
    flags=re.M,
)
assert ids, "No wsv-* todos found in plan YAML"
print(f"ok: plan_todos={len(ids)}")
PY

# 2) Proof-of-life: native window scripts exist (they may run in CI/WSL only)
test -f "scripts/start-li-world-studio-window.ps1" || {
  echo "ERROR: missing scripts/start-li-world-studio-window.ps1" >&2
  exit 1
}

# 3) Ensure we didn't regress into HTML mock as product truth
if grep -RIn "01-studio-workspace.html" src >/dev/null 2>&1; then
  echo "ERROR: src references HTML marketing mock" >&2
  exit 1
fi

echo "world-studio-gui-product-visual gates: ok"

