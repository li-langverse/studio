#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
import json
import re
from pathlib import Path

plan = Path("docs/superpowers/plans/2026-06-02-world-studio-gui-product-visual-loop.md").read_text(encoding="utf-8")
items = re.findall(
  r"^- id: (wsv-\S+)\\s*\\r?\\n\\s+content: .*?\\r?\\n\\s+status: (\\w+)",
  plan,
  flags=re.M,
)
assert items, "No wsv-* todos found"
pending = [i for i,s in items if s != "done"]
if pending:
  print("GOAL_INCOMPLETE")
  print("pending:", ", ".join(pending))
  raise SystemExit(1)

# Require screenshot manifest to exist and list at least one PNG
manifest_path = Path("data/world-studio-gui-product-visual-loop/latest-screenshots.json")
if not manifest_path.exists():
  print("GOAL_INCOMPLETE")
  print("missing:", str(manifest_path))
  raise SystemExit(1)

data = json.loads(manifest_path.read_text(encoding="utf-8"))
pngs = data.get("pngs", [])
if not isinstance(pngs, list) or not pngs:
  print("GOAL_INCOMPLETE")
  print("manifest has no pngs[]")
  raise SystemExit(1)

# Heuristic: demand at least one 1280x720 capture and minimum file size (entropy proxy)
root = Path(".").resolve()
ok_1280 = False
small = []
for rel in pngs:
  p = (root / rel).resolve()
  if not p.exists():
    small.append(f"missing:{rel}")
    continue
  if "1280x720" in p.name:
    ok_1280 = True
  if p.stat().st_size < 40000:
    small.append(f"small:{rel}:{p.stat().st_size}")

if not ok_1280:
  print("GOAL_INCOMPLETE")
  print("need at least one 1280x720 png")
  raise SystemExit(1)

if small:
  print("GOAL_INCOMPLETE")
  print("png_heuristics:", ", ".join(small[:10]))
  raise SystemExit(1)

print("GOAL_COMPLETE")
PY

