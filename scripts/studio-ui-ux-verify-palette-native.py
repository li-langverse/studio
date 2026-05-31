#!/usr/bin/env python3
"""Validate native palette latency bench hook (UX-04, studio-ux-22)."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HOOK = ROOT / "packages/li-ui/bench/palette_latency.toml"


def fail(msg: str) -> None:
    print(f"studio-ui-ux-verify-palette-native: {msg}", file=sys.stderr)
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
    open_sec = hook.get("open") or {}
    filter_sec = hook.get("filter") or {}

    if not meta.get("native_pixels"):
        fail("meta.native_pixels must be true for studio-ux-22")
    if meta.get("bench_native_fn") != "studio_palette_bench_native":
        fail("meta.bench_native_fn must be studio_palette_bench_native")

    budget_open = float(meta.get("budget_open_ms", 50))
    budget_filter = float(meta.get("budget_filter_ms", 30))
    open_ms = float(open_sec.get("elapsed_ms", bench.get("worst_open_ms", 999)))
    filter_ms = float(filter_sec.get("elapsed_ms", bench.get("worst_filter_ms", 999)))

    if open_ms > budget_open:
        fail(f"open elapsed {open_ms}ms > budget {budget_open}ms")
    if filter_ms > budget_filter:
        fail(f"filter elapsed {filter_ms}ms > budget {budget_filter}ms")
    if not open_sec.get("within_budget", False):
        fail("open.within_budget must be true")
    if not filter_sec.get("within_budget", False):
        fail("filter.within_budget must be true")
    if not open_sec.get("native_pixels", False):
        fail("open.native_pixels must be true")

    out = ROOT / "data/studio-ui-ux-plan-loop/latest-palette-native.json"
    out.write_text(
        json.dumps(
            {
                "pass": True,
                "status": "native",
                "open_ms": open_ms,
                "filter_ms": filter_ms,
                "budget_open_ms": budget_open,
                "budget_filter_ms": budget_filter,
                "bench_native_fn": meta.get("bench_native_fn"),
                "hook_version": meta.get("hook_version"),
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(
        "studio-ui-ux-verify-palette-native: ok "
        f"open={open_ms}ms filter={filter_ms}ms native_pixels=true"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
