#!/usr/bin/env python3
"""Validate keyboard journey manifest + bench hook (UX-09, studio-ux-18)."""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "data/studio-ui-ux-plan-loop/keyboard-journey-manifest.json"
HOOK_REL = Path("packages/li-gui/bench/keyboard_journey.toml")


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
    print(f"studio-ui-ux-verify-keyboard-journey: {msg}", file=sys.stderr)
    sys.exit(1)


def load_toml(path: Path) -> dict:
    import tomllib

    return tomllib.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    if not MANIFEST.is_file():
        fail(f"missing {MANIFEST.relative_to(ROOT)}")
    if not HOOK.is_file():
        fail(f"missing {HOOK.relative_to(ROOT)}")

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    hook = load_toml(HOOK)
    meta = hook.get("meta") or {}
    bench = hook.get("bench") or {}
    steps = hook.get("step") or []

    if manifest.get("bench_hook") != "packages/li-gui/bench/keyboard_journey.toml":
        fail("manifest.bench_hook mismatch")

    tab_steps = [s for s in steps if isinstance(s, dict) and s.get("kind") == "tab"]
    shortcut_steps = [s for s in steps if isinstance(s, dict) and s.get("kind") == "shortcut"]
    if len(tab_steps) < 3:
        fail("keyboard_journey.toml needs >=3 tab steps")
    if not shortcut_steps:
        fail("keyboard_journey.toml missing shortcut step (Cmd+K)")

    budget_tab = float(meta.get("budget_tab_ms", 16))
    budget_shortcut = float(meta.get("budget_shortcut_ms", 16))
    worst = float(bench.get("worst_elapsed_ms", 999))
    if worst > budget_tab:
        fail(f"worst tab elapsed {worst}ms > budget {budget_tab}ms")

    for s in tab_steps:
        elapsed = float(s.get("elapsed_ms", 999))
        if elapsed > budget_tab:
            fail(f"tab step {s.get('id')} elapsed {elapsed}ms > {budget_tab}ms")
        if not s.get("within_budget", False):
            fail(f"tab step {s.get('id')} within_budget=false")

    for s in shortcut_steps:
        elapsed = float(s.get("elapsed_ms", 999))
        if elapsed > budget_shortcut:
            fail(f"shortcut step elapsed {elapsed}ms > {budget_shortcut}ms")
        if s.get("key") != "k" or s.get("mod") != "cmd":
            fail("palette shortcut must be Cmd+K")

    if not bench.get("palette_shortcut_ok", False):
        fail("bench.palette_shortcut_ok must be true")

    tab_order = manifest.get("tab_order") or []
    if tab_order[:3] != ["dock", "viewport", "inspector"]:
        fail(f"unexpected tab_order prefix: {tab_order[:3]}")

    out = ROOT / "data/studio-ui-ux-plan-loop/latest-keyboard-journey.json"
    out.write_text(
        json.dumps(
            {
                "pass": True,
                "step_count": len(steps),
                "tab_steps": len(tab_steps),
                "shortcut_steps": len(shortcut_steps),
                "worst_elapsed_ms": worst,
                "budget_tab_ms": budget_tab,
                "budget_shortcut_ms": budget_shortcut,
                "harness_journey_id": manifest.get("harness_journey_id"),
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(
        "studio-ui-ux-verify-keyboard-journey: ok "
        f"steps={len(steps)} worst={worst}ms budget_tab={budget_tab}ms"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
