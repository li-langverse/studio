#!/usr/bin/env python3
"""Autonomous GUI library plan loop — Function·Layout·Design until Phases 0–5 land.

Usage:
  export CURSOR_API_KEY=cursor_...
  export LI_CURSOR_AGENTS_ROOT=/path/to/li-cursor-agents
  ./scripts/world-studio-gui-plan-loop.py --once

State: data/world-studio-gui-plan-loop/state.json
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOOP_BRANCH = os.environ.get("WORLD_STUDIO_GUI_PR_BRANCH", "cursor/world-studio-gui-library-plan")
PLAN = ROOT / "docs/superpowers/plans/2026-05-31-world-studio-gui-library-plan-loop.md"
HUB = ROOT / "docs/GUI-LIBRARY-PLAN.md"
STATE_DIR = ROOT / "data/world-studio-gui-plan-loop"
STATE_FILE = STATE_DIR / "state.json"
GATES = ROOT / "scripts/world-studio-gui-plan-gates.sh"
COMPLETION = ROOT / "scripts/world-studio-gui-plan-completion-gate.sh"
ASSESSMENT = STATE_DIR / "latest-iteration-assessment.json"


def load_plan_todos() -> list[dict]:
    text = PLAN.read_text(encoding="utf-8")
    m = re.search(r"^todos:\s*\n(.*)^---\s*$", text, re.MULTILINE | re.DOTALL)
    block = m.group(1) if m else ""
    todos: list[dict] = []
    for match in re.finditer(
        r"- id: (\S+)\n\s+content: \"?([^\"\n]+)\"?\n\s+status: (\w+)",
        block,
    ):
        todos.append(
            {"id": match.group(1), "content": match.group(2).strip(), "status": match.group(3)}
        )
    return todos


def wave_tier(todo_id: str) -> tuple[int, str]:
    m = re.match(r"wsg-w(\d+)-", todo_id)
    wave = int(m.group(1)) if m else 99
    return (wave, todo_id)


def pick_next(todos: list[dict], state: dict) -> dict | None:
    completed = set(state.get("completed_ids", []))
    id_order = {t["id"]: i for i, t in enumerate(todos)}

    def order_key(t: dict) -> tuple[int, int, int]:
        status_rank = 0 if t["status"] == "in_progress" else 1
        wave, _ = wave_tier(t["id"])
        return (status_rank, wave, id_order.get(t["id"], 999))

    open_todos = [
        t
        for t in todos
        if t["id"].startswith("wsg-w")
        and t["status"] in ("in_progress", "pending")
        and t["id"] not in completed
    ]
    if not open_todos:
        return None
    open_todos.sort(key=order_key)
    return open_todos[0]


def run_cmd(script: Path) -> tuple[bool, str]:
    if not script.is_file():
        return False, f"missing: {script}"
    proc = subprocess.run(
        ["bash", str(script)],
        cwd=ROOT,
        env={**os.environ, "LI_REPO_ROOT": str(ROOT), "STUDIO_ROOT": str(ROOT)},
        capture_output=True,
        text=True,
    )
    out = (proc.stdout or "") + (proc.stderr or "")
    return proc.returncode == 0, out[-8000:]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--once", action="store_true")
    args = parser.parse_args()

    STATE_DIR.mkdir(parents=True, exist_ok=True)
    if not PLAN.is_file():
        print(f"missing plan: {PLAN}", file=sys.stderr)
        return 1
    if not HUB.is_file():
        print(f"missing hub: {HUB}", file=sys.stderr)
        return 1

    ok, out = run_cmd(COMPLETION)
    if ok:
        print("GUI library plan complete — completion gate passed")
        return 0

    todos = load_plan_todos()
    state = json.loads(STATE_FILE.read_text(encoding="utf-8")) if STATE_FILE.is_file() else {}
    nxt = pick_next(todos, state)
    if not nxt:
        print("No open wsg-w* todos but completion gate failed:", out[-2000:], file=sys.stderr)
        return 1

    print(f"Next todo: {nxt['id']} — {nxt['content']}")
    gates_ok, gates_out = run_cmd(GATES)
    print(gates_out[-4000:])
    if not gates_ok:
        print("Progress gates failed", file=sys.stderr)
        return 1

    assessment = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "branch": LOOP_BRANCH,
        "next_todo": nxt["id"],
        "native_only": True,
        "pass": gates_ok,
    }
    ASSESSMENT.write_text(json.dumps(assessment, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {ASSESSMENT}")
    return 0 if args.once else 0


if __name__ == "__main__":
    raise SystemExit(main())
