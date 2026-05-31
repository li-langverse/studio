#!/usr/bin/env python3
"""Write per-iteration report under docs/reports/world-studio/iterations/."""
from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / "data/world-studio-plan-loop/state.json"
ASSESS = ROOT / "data/world-studio-plan-loop/latest-iteration-assessment.json"
OUT_DIR = ROOT / "docs/reports/world-studio/iterations"


def main() -> int:
    todo_id = sys.argv[1] if len(sys.argv) > 1 else "unknown"
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    out = OUT_DIR / f"{stamp}-{todo_id}.md"

    state = json.loads(STATE.read_text()) if STATE.is_file() else {}
    assess = json.loads(ASSESS.read_text()) if ASSESS.is_file() else {}

    lines = [
        f"# World Studio iteration — `{todo_id}`",
        "",
        f"_UTC {datetime.now(timezone.utc).isoformat()}_",
        "",
        "## Assessment",
        "",
    ]
    if assess:
        lines.append(f"- **pass:** {assess.get('pass', False)}")
        lines.append(f"- **native_only:** {assess.get('native_only', True)}")
        lines.append(f"- **wps_touched:** {assess.get('wps_touched', [])}")
        lines.append(f"- **notes:** {assess.get('notes', '')}")
    else:
        lines.append("_No latest-iteration-assessment.json — agent must write this file._")

    lines.extend(["", "## Loop state", "", f"- iterations: {state.get('iterations', 0)}", ""])
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
