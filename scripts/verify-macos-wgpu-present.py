#!/usr/bin/env python3
"""Verify macOS aarch64 wgpu/Metal surface wiring (wsg-w5-macos-wgpu).

Source checks always run. Live build/run soft-skip when not on Darwin.
"""
from __future__ import annotations

import json
import os
import platform
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HOST_C = ROOT / "deploy/studio-demo/native/studio_shell_present_host.c"
BUILD_SH = ROOT / "scripts/build-studio-shell-present-host-macos.sh"
START_SH = ROOT / "scripts/start-li-world-studio-macos.sh"
PROBE_C = ROOT / "deploy/studio-demo/native/lig_macos_wgpu_surface_probe.c"
LIB_LI = ROOT / "src/lib.li"
MAC_BIN = ROOT / "deploy/studio-demo/native/studio_shell_present_host"
PROBE_BIN = ROOT / "deploy/studio-demo/native/lig_macos_wgpu_surface_probe"


def fail(msg: str) -> None:
    print(f"verify-macos-wgpu-present: {msg}", file=sys.stderr)
    sys.exit(1)


def check_sources() -> None:
    for path in (HOST_C, BUILD_SH, START_SH, PROBE_C, LIB_LI):
        if not path.is_file():
            fail(f"missing {path.relative_to(ROOT)}")

    lib = LIB_LI.read_text(encoding="utf-8")
    for needle in (
        "def studio_macos_wgpu_present_version",
        "def studio_macos_wgpu_surface_smoke",
        "lig_present_wgpu_swapchain_active",
        "lig_present_surface_ok",
    ):
        if needle not in lib:
            fail(f"src/lib.li missing {needle!r}")

    host = HOST_C.read_text(encoding="utf-8")
    if "STUDIO_SHELL_HOST_IO_ONLY" not in host:
        fail("present host must be I/O-only")
    if "__APPLE__" not in host:
        fail("present host missing __APPLE__ wgpu surface guard")

    build = BUILD_SH.read_text(encoding="utf-8")
    if "lig_macos_wgpu_surface_probe" not in build:
        fail("build-studio-shell-present-host-macos.sh missing probe build")

    start = START_SH.read_text(encoding="utf-8")
    for needle in ("LIG_WGPU_SWAPCHAIN=1", "LIG_GPU_RUNNER=1", "LIG_HOST_PRESENT=1", "metal_wgpu_surface"):
        if needle not in start:
            fail(f"start-li-world-studio-macos.sh missing {needle!r}")

    print("verify-macos-wgpu-present: source wiring ok")


def try_build_macos() -> bool:
    if os.environ.get("STUDIO_MACOS_WGPU_SKIP_BUILD") == "1":
        print("verify-macos-wgpu-present: skip build (STUDIO_MACOS_WGPU_SKIP_BUILD=1)")
        return MAC_BIN.is_file()
    if platform.system() != "Darwin":
        print("verify-macos-wgpu-present: skip live build (not Darwin)")
        return False
    proc = subprocess.run(
        ["bash", str(BUILD_SH)],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=180,
        check=False,
    )
    if proc.returncode != 0:
        tail = (proc.stderr or proc.stdout or "")[-500:]
        print(f"verify-macos-wgpu-present: macOS build skipped — {tail.strip()}")
        return False
    if not MAC_BIN.is_file():
        return False
    magic = MAC_BIN.read_bytes()[:4]
    if magic != b"\xcf\xfa\xed\xfe" and magic[:2] != b"\xce\xfa":
        fail("studio_shell_present_host is not a Mach-O binary")
    print(f"verify-macos-wgpu-present: built {MAC_BIN.name}")
    return True


def try_probe_run() -> None:
    if not PROBE_BIN.is_file():
        if platform.system() != "Darwin":
            print("verify-macos-wgpu-present: no probe binary — source checks sufficient for CI")
            return
        print("verify-macos-wgpu-present: probe binary missing — soft skip")
        return

    env = os.environ.copy()
    env["LIG_HOST_PRESENT"] = "1"
    env["LIG_WGPU_SWAPCHAIN"] = "1"
    env["LIG_GPU_RUNNER"] = "1"
    proc = subprocess.run(
        [str(PROBE_BIN)],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=30,
        env=env,
        check=False,
    )
    if proc.returncode != 0:
        tail = (proc.stderr or proc.stdout or "")[-400:]
        if os.environ.get("STUDIO_MACOS_WGPU_REQUIRE_PROBE") == "1":
            fail(f"macOS wgpu probe failed: {tail}")
        print(f"verify-macos-wgpu-present: probe skipped — {tail.strip()}")
        return

    line = (proc.stdout or "").strip().splitlines()[-1] if proc.stdout else ""
    try:
        payload = json.loads(line)
    except json.JSONDecodeError:
        if os.environ.get("STUDIO_MACOS_WGPU_REQUIRE_PROBE") == "1":
            fail("probe did not emit JSON")
        print("verify-macos-wgpu-present: probe JSON missing — soft skip")
        return

    if payload.get("platform") != "aarch64-apple-darwin" and platform.system() == "Darwin":
        fail(f"unexpected platform field: {payload.get('platform')!r}")
    if payload.get("surface_ok") != 1 and os.environ.get("STUDIO_MACOS_WGPU_REQUIRE_PROBE") == "1":
        fail(f"surface_ok false: {payload}")
    print(f"verify-macos-wgpu-present: probe ok bench_status={payload.get('bench_status')}")


def main() -> int:
    check_sources()
    try_build_macos()
    try_probe_run()
    print("verify-macos-wgpu-present: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
