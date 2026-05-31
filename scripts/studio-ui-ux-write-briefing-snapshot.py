#!/usr/bin/env python3
"""Refresh studio UI/UX briefing snapshot from org agent-briefing + plan-loop state."""
from __future__ import annotations

import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STATE_DIR = ROOT / "data/studio-ui-ux-plan-loop"
OUT = STATE_DIR / "latest-briefing-snapshot.json"


def load_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def find_briefing() -> Path | None:
    env = os.environ.get("LI_AGENT_BRIEFING_JSON")
    if env and Path(env).is_file():
        return Path(env)
    candidates = [
        ROOT / "../../benchmarks/data/latest/agent-briefing.json",
        ROOT / "../../../benchmarks/data/latest/agent-briefing.json",
        Path("/home/s4il0r/Documents/Cursor/li-langverse/benchmarks/data/latest/agent-briefing.json"),
    ]
    for c in candidates:
        p = c.resolve()
        if p.is_file():
            return p
    return None


def studio_gaps(bench: dict, deps: dict, ux: dict) -> list[dict]:
    gaps: list[dict] = []
    swap = bench.get("wgpu_swapchain") or {}
    if swap.get("status") == "blocked_runner":
        gaps.append(
            {
                "id": "studio-ux-21-wgpu-swapchain-gpu-runner",
                "severity": "medium",
                "reason": "wgpu swapchain readback blocked until org GPU runner + LIG_WGPU_SWAPCHAIN=1 + LIG_GPU_RUNNER=1",
            }
        )
    pal = bench.get("palette_latency") or {}
    if pal.get("status") == "simulate":
        gaps.append(
            {
                "id": "studio-ux-22-palette-native-latency",
                "severity": "low",
                "reason": "palette open/filter latency simulate-only; native SDL shell measurement pending",
            }
        )
    agent = bench.get("agent_chrome") or {}
    if agent.get("status") != "native":
        gaps.append(
            {
                "id": "studio-ux-23-agent-chrome-native",
                "severity": "medium",
                "reason": "agent chrome composables exist; native shell stream wiring vs Cursor SOTA",
            }
        )
    elif isinstance((ux.get("dimensions") or {}).get("UX-06"), dict) and float(
        (ux.get("dimensions") or {}).get("UX-06", {}).get("score", 3)
    ) < 2.8:
        gaps.append(
            {
                "id": "studio-ux-23-agent-chrome-native",
                "severity": "low",
                "reason": "agent stream native but UX-06 score below SOTA bar — progress UI polish",
            }
        )
    if not deps.get("ready_for_wgpu_swapchain"):
        gaps.append(
            {
                "id": "studio-ux-24-gpu-runner-deps",
                "severity": "low",
                "reason": "Vulkan pkg-config, nvidia-smi, or LIG_GPU_RUNNER env not active on this runner",
            }
        )
    return gaps


FOLLOW_UP_BY_GAP = {
    "studio-ux-21-wgpu-swapchain-gpu-runner": {
        "repo": "lic",
        "title": "feat(studio-ui): wgpu swapchain readback on org GPU runner (studio-ux-21)",
        "labels": ["studio-ui", "PH-UX", "wgpu"],
    },
    "studio-ux-22-palette-native-latency": {
        "repo": "lic",
        "title": "feat(studio-ui): native palette latency on SDL shell (studio-ux-22)",
        "labels": ["studio-ui", "PH-UX", "UX-04"],
    },
    "studio-ux-23-agent-chrome-native": {
        "repo": "lic",
        "title": "feat(studio-ui): agent chrome native stream wiring (studio-ux-23)",
        "labels": ["studio-ui", "agentic", "UX-06"],
    },
    "studio-ux-24-gpu-runner-deps": {
        "repo": "lic",
        "title": "chore(studio-ui): org GPU runner Vulkan deps + wgpu swapchain CI (studio-ux-24)",
        "labels": ["studio-ui", "PH-UX", "ci"],
    },
}


def follow_up_issues(gaps: list[dict]) -> list[dict]:
    out: list[dict] = []
    for gap in gaps:
        item = FOLLOW_UP_BY_GAP.get(gap.get("id", ""))
        if item:
            out.append(item)
    return out


def briefing_signals(briefing: dict) -> dict:
    rec = briefing.get("recommended_agents") or []
    studio_agents = [a for a in rec if "studio" in str(a.get("agent", "")).lower()]
    audit = briefing.get("ecosystem_audit") or {}
    metrics = audit.get("metrics") or {}
    return {
        "briefing_generated_at": briefing.get("generated_at"),
        "recommended_studio_agents": studio_agents,
        "open_prs": metrics.get("open_prs"),
        "failed_prs": metrics.get("failed_prs"),
        "repos_missing_ci_main": metrics.get("repos_missing_ci_main"),
        "master_plan_open_items": (briefing.get("plan_completion_audit") or {})
        .get("summary", {})
        .get("total_findings"),
        "workspace_dirty_count": (briefing.get("workspace_dirty_sweep") or {}).get("dirty_count"),
    }


def main() -> int:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    briefing_path = find_briefing()
    briefing = load_json(briefing_path) if briefing_path else {}
    state = load_json(STATE_DIR / "state.json")
    bench = load_json(STATE_DIR / "latest-bench.json")
    ux = load_json(STATE_DIR / "latest-ux-assessment.json")
    deps = load_json(STATE_DIR / "latest-capture-deps.json")

    branch = subprocess.run(
        ["git", "-C", str(ROOT), "branch", "--show-current"],
        capture_output=True,
        text=True,
    ).stdout.strip() or "unknown"
    sha = subprocess.run(
        ["git", "-C", str(ROOT), "rev-parse", "--short", "HEAD"],
        capture_output=True,
        text=True,
    ).stdout.strip() or "unknown"

    gaps = studio_gaps(bench, deps, ux)
    payload = {
        "schema": "li_studio_briefing_snapshot_v1",
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "todo_id": os.environ.get("STUDIO_UI_UX_ITERATION", "studio-ux-20-proactive-sweep-20260530"),
        "branch": branch,
        "head": sha,
        "briefing_path": str(briefing_path) if briefing_path else None,
        "briefing_signals": briefing_signals(briefing),
        "plan_loop": {
            "completed_count": len(state.get("completed_ids", [])),
            "iterations": state.get("iterations", 0),
            "gates_pass": bench.get("gates_pass"),
            "ux_pass": ux.get("pass"),
            "ux_avg_score": ux.get("avg_score"),
        },
        "ph_ux_gates": {
            "viewport_fps": (bench.get("gates") or {}).get("viewport_fps"),
            "panel_switch_ms": (bench.get("gates") or {}).get("panel_switch_ms"),
            "studio_load_ms": (bench.get("gates") or {}).get("studio_load_ms"),
            "memory_mib": (bench.get("memory_mib") or {}).get("peak_observed_mib"),
        },
        "capture_deps": {
            "ready_for_native_capture": deps.get("ready_for_native_capture"),
            "ready_for_wgpu_swapchain": deps.get("ready_for_wgpu_swapchain"),
            "gaps": deps.get("gaps", []),
        },
        "wave_4_gaps": gaps,
        "follow_up_issues": follow_up_issues(gaps),
    }
    OUT.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"studio-ui-ux-write-briefing-snapshot: ok → {OUT} (gaps={len(gaps)})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
