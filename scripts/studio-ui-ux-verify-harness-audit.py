#!/usr/bin/env python3
"""Run world-studio-demo ux-harness on Linux without --mock; require pass + journeys + agentic SOTA."""
from __future__ import annotations

import json
import os
import platform
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fail(msg: str) -> None:
    print(f"studio-ui-ux-verify-harness-audit: {msg}", file=sys.stderr)
    sys.exit(1)


def agents_root() -> Path | None:
    env = os.environ.get("LI_CURSOR_AGENTS_ROOT", "")
    if env:
        p = Path(env)
        if (p / "ux-harness/run_audit.py").is_file():
            return p
    for rel in ("../li-cursor-agents", "../../li-cursor-agents"):
        p = (ROOT / rel).resolve()
        if (p / "ux-harness/run_audit.py").is_file():
            return p
    return None


def main() -> int:
    if platform.system() != "Linux":
        print("studio-ui-ux-verify-harness-audit: skip (non-Linux host)")
        return 0

    agents = agents_root()
    if agents is None:
        print(
            "studio-ui-ux-verify-harness-audit: skip — ux-harness not on runner "
            "(set LI_CURSOR_AGENTS_ROOT or checkout li-cursor-agents sibling)"
        )
        return 0

    run_audit = agents / "ux-harness/run_audit.py"
    out_dir = ROOT / "data/studio-ui-ux-plan-loop/harness-verify"
    out_dir.mkdir(parents=True, exist_ok=True)

    env = {**os.environ, "LIC_ROOT": str(ROOT)}
    proc = subprocess.run(
        [
            sys.executable,
            str(run_audit),
            "--target",
            "world-studio-demo",
            "--mode",
            "both",
            "--out-dir",
            str(out_dir),
        ],
        cwd=ROOT,
        env=env,
        capture_output=True,
        text=True,
        timeout=60,
    )
    if proc.returncode != 0:
        fail(f"run_audit exit {proc.returncode}\n{proc.stderr[-1500:]}")

    ui_path = out_dir / "ui-audit.json"
    ux_path = out_dir / "ux-audit.json"
    if not ui_path.is_file() or not ux_path.is_file():
        fail("missing ui-audit.json or ux-audit.json")

    ui = json.loads(ui_path.read_text(encoding="utf-8"))
    ux = json.loads(ux_path.read_text(encoding="utf-8"))
    ui_t = (ui.get("targets") or [{}])[0]
    ux_t = (ux.get("targets") or [{}])[0]

    if ui_t.get("status") != "pass":
        fail(f"world-studio-demo UI status={ui_t.get('status')} reason={ui_t.get('skip_reason')}")
    fixture = ui_t.get("fixture", "")
    if not fixture or not Path(fixture).is_file():
        fail(f"fixture missing or not on disk: {fixture!r}")

    if ux_t.get("status") != "pass":
        fail(f"world-studio-demo UX status={ux_t.get('status')} reason={ux_t.get('skip_reason')}")

    journey_ids = {j.get("id") for j in ux_t.get("journeys") or [] if isinstance(j, dict)}
    for required in (
        "studio_workspace",
        "command_palette",
        "vertical_profile",
        "keyboard_first_workflow",
    ):
        if required not in journey_ids:
            fail(f"missing journey id={required} in ux audit")

    sota = set(ux_t.get("sota_refs") or [])
    for required in ("cursor-agent", "linear-app", "github-copilot-workspace"):
        if required not in sota:
            fail(f"missing agentic_ai sota ref {required!r} (have {sorted(sota)})")

    for name, data in (("latest-ui-audit.json", ui), ("latest-ux-audit.json", ux)):
        (ROOT / "data/studio-ui-ux-plan-loop" / name).write_text(
            json.dumps(data, indent=2) + "\n", encoding="utf-8"
        )

    print(
        "studio-ui-ux-verify-harness-audit: ok "
        f"fixture={Path(fixture).name} journeys={len(journey_ids)} sota={len(sota)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
