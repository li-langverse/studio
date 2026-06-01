#!/usr/bin/env python3
"""Validate wgpu swapchain readback bench hook (studio-ux-19)."""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LATEST = ROOT / "data/studio-ui-ux-plan-loop/latest-bench.json"


def lic_root() -> Path | None:
    env = os.environ.get("LIC_ROOT", "")
    if env:
        p = Path(env)
        if (p / "packages/li-ui").is_dir():
            return p
    for candidate in (ROOT.parent / "lic", ROOT / "lic"):
        if (candidate / "packages/li-ui").is_dir():
            return candidate
    return None


def hook_path() -> Path | None:
    for rel in (
        "packages/lig/bench/wgpu_smoke.toml",
        "packages/li-gpu/bench/wgpu_smoke.toml",
    ):
        p = ROOT / rel
        if p.is_file():
            return p
        lic = lic_root()
        if lic is not None:
            alt = lic / rel
            if alt.is_file():
                return alt
    return None


def fail(msg: str) -> None:
    print(f"studio-ui-ux-verify-wgpu-swapchain: {msg}", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    hook = hook_path()
    if hook is None:
        fail("missing packages/lig/bench/wgpu_smoke.toml (or legacy li-gpu path)")
    if not LATEST.is_file():
        fail("missing latest-bench.json — run bench-studio-viewport-perf.sh")

    import tomllib

    hook_data = tomllib.loads(hook.read_text(encoding="utf-8"))
    if "wgpu_swapchain" not in hook_data:
        fail("wgpu_smoke.toml missing [wgpu_swapchain]")

    bench = json.loads(LATEST.read_text(encoding="utf-8"))
    ws = bench.get("wgpu_swapchain")
    if not ws:
        fail("latest-bench.json missing wgpu_swapchain")

    status = ws.get("status", "")
    env_on = os.environ.get("LIG_WGPU_SWAPCHAIN", "") == "1"
    gate = (bench.get("gates") or {}).get("wgpu_swapchain_readback") or {}

    if status not in ("blocked_runner", "swapchain_pass", "pending"):
        fail(f"unexpected wgpu_swapchain.status={status!r}")

    if status == "blocked_runner":
        if not ws.get("honest_blocked"):
            fail("blocked_runner but honest_blocked false")
        print(
            "studio-ui-ux-verify-wgpu-swapchain: ok "
            f"status={status} env_active={env_on} (GPU runner deferred)"
        )
        return

    if status == "swapchain_pass":
        if not ws.get("meets_target"):
            fail("swapchain_pass but meets_target false")
        if not ws.get("native_pixels"):
            fail("swapchain_pass but native_pixels false")
        print("studio-ui-ux-verify-wgpu-swapchain: ok swapchain_pass")
        return

    fail(f"unhandled status={status!r} env_active={env_on} gate={gate}")


if __name__ == "__main__":
    main()
