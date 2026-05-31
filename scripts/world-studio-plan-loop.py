#!/usr/bin/env python3
"""Autonomous World Studio master plan loop — native Li studio until all WPs land.

Usage:
  export CURSOR_API_KEY=cursor_...
  export LI_CURSOR_AGENTS_ROOT=/path/to/li-cursor-agents
  ./scripts/world-studio-plan-loop.py --once
  ./scripts/world-studio-plan-continuous.sh

State: data/world-studio-plan-loop/state.json
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import threading
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOOP_BRANCH = os.environ.get("WORLD_STUDIO_PR_BRANCH", "cursor/world-studio-master-plan-loop")
PLAN = ROOT / "docs/superpowers/plans/2026-05-29-world-studio-master-plan-loop.md"
MASTER = ROOT / "docs/game-dev/WORLD-STUDIO-MASTER-PLAN.md"
STATE_DIR = ROOT / "data/world-studio-plan-loop"
STATE_FILE = STATE_DIR / "state.json"
GATES = ROOT / "scripts/world-studio-plan-gates.sh"
COMMIT = ROOT / "scripts/world-studio-plan-commit-push.sh"
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
    """Order by wave: w0 < w1 < ... < w6."""
    m = re.match(r"wsm-w(\d+)-", todo_id)
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
        if t["id"].startswith("wsm-w")
        and t["status"] in ("in_progress", "pending")
        and t["id"] not in completed
    ]
    if not open_todos:
        return None
    open_todos.sort(key=order_key)
    return open_todos[0]


def run_gates() -> tuple[bool, str]:
    if not GATES.is_file():
        return False, f"missing gates: {GATES}"
    proc = subprocess.run(
        ["bash", str(GATES)],
        cwd=ROOT,
        env={**os.environ, "LI_REPO_ROOT": str(ROOT)},
        capture_output=True,
        text=True,
    )
    out = (proc.stdout or "") + (proc.stderr or "")
    return proc.returncode == 0, out[-8000:]


def read_assessment_pass() -> bool:
    if not ASSESSMENT.is_file():
        return False
    try:
        data = json.loads(ASSESSMENT.read_text(encoding="utf-8"))
        return bool(data.get("pass"))
    except json.JSONDecodeError:
        return False


def commit_push(todo_id: str) -> None:
    if not COMMIT.is_file():
        return
    subprocess.run(
        ["bash", str(COMMIT), todo_id, f"feat(studio): {todo_id} — world studio plan iteration"],
        cwd=ROOT,
        check=False,
    )


def agents_root() -> Path | None:
    for candidate in [
        os.environ.get("LI_CURSOR_AGENTS_ROOT"),
        ROOT.parent / "li-cursor-agents",
        Path("/workspace/li-cursor-agents"),
    ]:
        if not candidate:
            continue
        p = Path(candidate)
        if (p / "package.json").is_file():
            return p
    return None


def _tee_stream(pipe, logf, out) -> None:
    for line in iter(pipe.readline, ""):
        out.write(line)
        out.flush()
        logf.write(line)
        logf.flush()


def loop_workflow_env() -> dict[str, str]:
    return {
        "LI_WORLD_STUDIO_PLAN_LOOP": "1",
        "LI_REPO_WORKFLOW_REPO": "lic",
        "LI_REPO_WORKFLOW_BRANCH": LOOP_BRANCH,
        "LI_REPO_WORKFLOW_TRACK_REMOTE": "1",
        "LI_REPO_WORKFLOW_OPEN_PR": "1",
        "WORLD_STUDIO_PR_BRANCH": LOOP_BRANCH,
    }


def _git(cwd: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, check=False)


def recover_unpushed_work(lic_root: Path, agents_root_path: Path | None, branch: str) -> None:
    if not (os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")):
        return

    def push_repo(repo_dir: Path, label: str) -> None:
        if not (repo_dir / ".git").is_dir():
            return
        cur = _git(repo_dir, "branch", "--show-current").stdout.strip()
        if cur and cur != branch:
            return
        if cur != branch:
            _git(repo_dir, "checkout", "-B", branch, f"origin/{branch}")
        if _git(repo_dir, "status", "--porcelain").stdout.strip():
            _git(repo_dir, "add", "-A")
            _git(repo_dir, "commit", "-m", f"chore(world-studio): plan loop recovery ({label})")
        ahead = _git(repo_dir, "rev-list", "--count", f"origin/{branch}..HEAD")
        if ahead.returncode == 0 and ahead.stdout.strip() not in ("", "0"):
            _git(repo_dir, "push", "-u", "origin", branch)

    push_repo(lic_root, "lic")
    if not agents_root_path:
        return
    ws = agents_root_path / "data" / "workspaces"
    if not ws.is_dir():
        return
    for org_dir in ws.iterdir():
        lic_dir = org_dir / "lic"
        if not lic_dir.is_dir():
            continue
        for run_dir in sorted(lic_dir.iterdir(), key=lambda p: p.stat().st_mtime, reverse=True)[:3]:
            repo = run_dir / "repo"
            if (repo / ".git").is_dir():
                push_repo(repo, run_dir.name)


def agent_timeout_sec() -> int | None:
    raw = os.environ.get("WORLD_STUDIO_AGENT_TIMEOUT_SEC", "7200").strip()
    if raw in ("0", "none", "off"):
        return None
    try:
        return max(60, int(raw))
    except ValueError:
        return 7200


def run_subprocess_streaming(cmd: list[str], cwd: Path, env: dict[str, str], log_path: Path) -> int:
    timeout = agent_timeout_sec()
    with log_path.open("w", encoding="utf-8") as logf:
        logf.write(f"# cmd: {' '.join(cmd)}\n\n")
        proc = subprocess.Popen(
            cmd,
            cwd=str(cwd),
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
        )
        threads = [
            threading.Thread(target=_tee_stream, args=(proc.stdout, logf, sys.stdout), daemon=True),
            threading.Thread(target=_tee_stream, args=(proc.stderr, logf, sys.stderr), daemon=True),
        ]
        for t in threads:
            t.start()
        try:
            rc = proc.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            proc.kill()
            rc = proc.wait()
        finally:
            for t in threads:
                t.join(timeout=2)
        return rc


def build_instruction(todo: dict) -> str:
    master_excerpt = ""
    if MASTER.is_file():
        master_excerpt = MASTER.read_text(encoding="utf-8")[:12000]
    branch = LOOP_BRANCH
    return f"""# World Studio master plan iteration — todo `{todo['id']}`

**Plan loop:** `{PLAN.relative_to(ROOT)}`
**Hub:** `{MASTER.relative_to(ROOT)}`
**Agent:** `world_studio_builder`

## Current todo
- **id:** {todo['id']}
- **content:** {todo['content']}

## Policy (mandatory)
- **Native Li only** — implement in `packages/li-studio`, `li-ui`, `li-gui`, `li-render`, `li-sim-*`.
- **Do NOT** add HTML/CSS/JS studio runtime demos (see `.cursor/rules/li-studio-demo-native-only.mdc`).
- **Proof gate:** run relevant `lic check` smokes; `lic build` before export/publish paths.
- Branch: `{branch}` — push; open/update PR; do not merge to main.

## Skills (read first)
- `.cursor/skills/studio-agentic-ux/SKILL.md`
- `.cursor/skills/studio-design-review/SKILL.md`
- `.cursor/skills/studio-ui-ux-rubric/SKILL.md`
- `.cursor/skills/explore-li-ecosystem/SKILL.md`

## Mandatory every iteration
1. Implement the todo slice on `{branch}`.
2. Run `./scripts/world-studio-plan-gates.sh`.
3. Write **`data/world-studio-plan-loop/latest-iteration-assessment.json`**:
```json
{{
  "pass": true,
  "todo_id": "{todo['id']}",
  "wps_touched": ["WP-..."],
  "smokes_run": ["li-tests/smoke/..."],
  "native_only": true,
  "notes": "What landed; what remains stub"
}}
```
4. Update plan YAML: set `{todo['id']}` status to `done` when gates green and slice complete.
5. PR body: WP IDs, smokes run, honesty notes (native_pixels, mock surfaces).

## Master plan excerpt
{master_excerpt}

## Deliverable
PR URL, gates output, assessment JSON path, updated plan todo status.
"""


def run_cursor_agent(todo: dict, dry_run: bool) -> tuple[int, str]:
    root = agents_root()
    if not root:
        return 2, "li-cursor-agents not found"

    instruction = build_instruction(todo)
    if dry_run:
        return 0, instruction

    if not os.environ.get("CURSOR_API_KEY") and not os.environ.get("CURSOR_SDK_KEY"):
        return 2, "CURSOR_API_KEY not set"

    dist = root / "dist/cli/run-agent.js"
    if not dist.is_file():
        subprocess.run(["npm", "run", "build"], cwd=root, check=True)

    agent = os.environ.get("WORLD_STUDIO_PLAN_AGENT", "world_studio_builder")
    goal_path = STATE_DIR / f"goal-{datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S')}.md"
    goal_path.write_text(instruction, encoding="utf-8")

    env = {
        **os.environ,
        **loop_workflow_env(),
        "PYTHONUNBUFFERED": "1",
        "LI_SDK_TERMINAL_STREAM": os.environ.get("LI_SDK_TERMINAL_STREAM", "1"),
        "LI_AGENT_MINIMAL_PROMPT": "1",
        "LI_CONTROL_PLANE_STORE": os.environ.get("LI_CONTROL_PLANE_STORE", "disk"),
        "LI_STACK_SKIP_SUPABASE": os.environ.get("LI_STACK_SKIP_SUPABASE", "1"),
        "LI_EXPORT_DISK_CACHE": os.environ.get("LI_EXPORT_DISK_CACHE", "1"),
        "LIC_ROOT": str(ROOT),
        "LI_AGENT_EXTRA_INSTRUCTION": instruction,
        "LI_AGENT_GOAL": instruction,
    }
    cmd = [
        "node",
        str(dist),
        "--agent",
        agent,
        "--cwd",
        str(ROOT),
        "--workflow-repo",
        "lic",
        "--goal-file",
        str(goal_path),
    ]

    STATE_DIR.mkdir(parents=True, exist_ok=True)
    log_path = STATE_DIR / f"iter-{datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S')}.log"
    rc = run_subprocess_streaming(cmd, root, env, log_path)
    recover_unpushed_work(ROOT, root, LOOP_BRANCH)
    return rc, f"log={log_path}"


def load_state() -> dict:
    if STATE_FILE.is_file():
        return json.loads(STATE_FILE.read_text(encoding="utf-8"))
    return {"completed_ids": [], "iterations": 0, "history": []}


def save_state(state: dict) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")


def mark_plan_todo_done(todo_id: str) -> None:
    if not PLAN.is_file():
        return
    text = PLAN.read_text(encoding="utf-8")
    pattern = rf"(- id: {re.escape(todo_id)}\n\s+content: \"?[^\"\n]+\"?\n\s+status: )\w+"
    new_text, n = re.subn(pattern, rf"\1done", text, count=1)
    if n:
        PLAN.write_text(new_text, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="World Studio master plan loop")
    parser.add_argument("--max", type=int, default=0)
    parser.add_argument("--once", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--skip-agent", action="store_true")
    parser.add_argument("--mark-done", metavar="ID")
    args = parser.parse_args()

    if args.mark_done:
        state = load_state()
        if args.mark_done not in state.setdefault("completed_ids", []):
            state["completed_ids"].append(args.mark_done)
        save_state(state)
        mark_plan_todo_done(args.mark_done)
        return 0

    if not PLAN.is_file():
        print(f"error: plan missing: {PLAN}", file=sys.stderr)
        return 1

    todos = load_plan_todos()
    state = load_state()
    max_iter = 1 if args.once else (args.max or 999)
    iteration = 0

    while iteration < max_iter:
        todo = pick_next(todos, state)
        if not todo:
            print("All wsm-w* todos complete — World Studio master plan done.")
            return 0

        print(f"\n=== world-studio iteration {iteration + 1}: {todo['id']} ===")

        if args.skip_agent:
            ok, gate_out = run_gates()
            return 0 if ok else 1

        code, msg = run_cursor_agent(todo, args.dry_run)
        try:
            print(msg, flush=True)
        except UnicodeEncodeError:
            sys.stdout.buffer.write(msg.encode("utf-8", errors="replace") + b"\n")
            sys.stdout.buffer.flush()
        if args.dry_run:
            return 0

        if code != 0:
            return code

        ok, gate_out = run_gates()
        print("gates: OK" if ok else "gates: FAIL")
        if not ok:
            print(gate_out[-1500:], file=sys.stderr)

        subprocess.run(
            [sys.executable, str(ROOT / "scripts/world-studio-plan-iteration-report.py"), todo["id"]],
            cwd=ROOT,
            check=False,
        )

        if ok:
            commit_push(todo["id"])
            mark_plan_todo_done(todo["id"])

        assess_ok = read_assessment_pass()

        state["iterations"] = state.get("iterations", 0) + 1
        state.setdefault("history", []).append(
            {
                "at": datetime.now(timezone.utc).isoformat(),
                "todo_id": todo["id"],
                "agent_exit": code,
                "gates_ok": ok,
                "assessment_pass": assess_ok,
            }
        )
        save_state(state)

        if not ok:
            return 1

        tid = todo["id"]
        if tid not in state.setdefault("completed_ids", []):
            state["completed_ids"].append(tid)
            save_state(state)

        iteration += 1
        todos = load_plan_todos()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
