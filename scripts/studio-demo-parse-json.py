#!/usr/bin/env python3
"""Map data/demo-scripts/*.demo.json name → STUDIO_DEMO_SCENARIO_ID for Li replay."""
from __future__ import annotations

import json
import sys
from pathlib import Path

SCENARIOS = {
    "workspace-tour": 1,
    "command-palette": 2,
    "agent-invoke": 3,
}


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: studio-demo-parse-json.py <path.demo.json>", file=sys.stderr)
        return 2
    path = Path(sys.argv[1])
    data = json.loads(path.read_text(encoding="utf-8"))
    name = data.get("name", path.stem.replace(".demo", ""))
    sid = SCENARIOS.get(name)
    if sid is None:
        print(f"unknown scenario name: {name}", file=sys.stderr)
        return 1
    print(sid)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
