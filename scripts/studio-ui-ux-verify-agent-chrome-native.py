#!/usr/bin/env python3
"""Validate native agent chrome stream bench hook (UX-06, studio-ux-23)."""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HOOK_REL = Path("packages/li-ui/bench/agent_chrome.toml")


def resolve_hook() -> Path:
    lic_root = os.environ.get("LIC_ROOT")
    if lic_root:
        candidate = Path(lic_root) / HOOK_REL
        if candidate.is_file():
            return candidate
    for sibling in (ROOT.parent / "lic", ROOT.parent.parent / "lic"):
        candidate = sibling / HOOK_REL
        if candidate.is_file():
            return candidate
    return ROOT / HOOK_REL


HOOK = resolve_hook()


def fail(msg: str) -> None:
    print(f"studio-ui-ux-verify-agent-chrome-native: {msg}", file=sys.stderr)
    sys.exit(1)


def load_toml(path: Path) -> dict:
    import tomllib

    return tomllib.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    if not HOOK.is_file():
        fail(f"missing {HOOK.relative_to(ROOT)}")

    hook = load_toml(HOOK)
    meta = hook.get("meta") or {}
    bench = hook.get("bench") or {}
    tick_sec = hook.get("tick") or {}
    cancel_sec = hook.get("cancel") or {}

    if not meta.get("native_pixels"):
        fail("meta.native_pixels must be true for studio-ux-23")
    if meta.get("bench_native_fn") != "studio_agent_bench_native":
        fail("meta.bench_native_fn must be studio_agent_bench_native")
    if meta.get("bench_shell_fn") != "studio_shell_agent_bench_native":
        fail("meta.bench_shell_fn must be studio_shell_agent_bench_native")

    budget_tick = float(meta.get("budget_tick_ms", 16))
    budget_cancel = float(meta.get("budget_cancel_ms", 16))
    tick_ms = float(tick_sec.get("elapsed_ms", bench.get("worst_tick_ms", 999)))
    cancel_ms = float(cancel_sec.get("elapsed_ms", bench.get("worst_cancel_ms", 999)))

    if tick_ms > budget_tick:
        fail(f"tick elapsed {tick_ms}ms > budget {budget_tick}ms")
    if cancel_ms > budget_cancel:
        fail(f"cancel elapsed {cancel_ms}ms > budget {budget_cancel}ms")
    if not tick_sec.get("within_budget", False):
        fail("tick.within_budget must be true")
    if not cancel_sec.get("within_budget", False):
        fail("cancel.within_budget must be true")
    if not cancel_sec.get("cancel_works", False):
        fail("cancel.cancel_works must be true")
    if int(bench.get("steps_completed", 0)) < 3:
        fail("bench.steps_completed must be >= 3")

    out = ROOT / "data/studio-ui-ux-plan-loop/latest-agent-chrome-native.json"
    out.write_text(
        json.dumps(
            {
                "pass": True,
                "status": "native",
                "tick_ms": tick_ms,
                "cancel_ms": cancel_ms,
                "budget_tick_ms": budget_tick,
                "budget_cancel_ms": budget_cancel,
                "steps_completed": bench.get("steps_completed"),
                "bench_native_fn": meta.get("bench_native_fn"),
                "bench_shell_fn": meta.get("bench_shell_fn"),
                "hook_version": meta.get("hook_version"),
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(
        "studio-ui-ux-verify-agent-chrome-native: ok "
        f"tick={tick_ms}ms cancel={cancel_ms}ms steps={bench.get('steps_completed')} native_pixels=true"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
