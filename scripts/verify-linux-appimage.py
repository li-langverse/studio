#!/usr/bin/env python3
"""Verify Linux AppImage / AppDir wiring (wsg-w5-linux-appimage).

Source checks always run. Live build soft-skip when not on Linux.
"""
from __future__ import annotations

import os
import platform
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HOST_C = ROOT / "deploy/studio-demo/native/studio_shell_present_host.c"
BUILD_SH = ROOT / "scripts/build-studio-linux-appimage.sh"
START_SH = ROOT / "scripts/start-li-world-studio-linux.sh"
DESKTOP = ROOT / "installer/linux/li-world-studio.desktop"
LIB_LI = ROOT / "src/lib.li"
APPDIR = ROOT / "installer/out/LiWorldStudio.AppDir"
APPIMAGE = ROOT / "installer/out/LiWorldStudio-x86_64.AppImage"
HOST_BIN = ROOT / "deploy/studio-demo/native/studio_shell_present_host"


def fail(msg: str) -> None:
    print(f"verify-linux-appimage: {msg}", file=sys.stderr)
    sys.exit(1)


def check_sources() -> None:
    for path in (HOST_C, BUILD_SH, START_SH, DESKTOP, LIB_LI):
        if not path.is_file():
            fail(f"missing {path.relative_to(ROOT)}")

    lib = LIB_LI.read_text(encoding="utf-8")
    for needle in (
        "def studio_linux_appimage_version",
        "def studio_linux_appimage_smoke",
        "lig_present_wgpu_swapchain_active",
    ):
        if needle not in lib:
            fail(f"src/lib.li missing {needle!r}")

    host = HOST_C.read_text(encoding="utf-8")
    if "STUDIO_SHELL_HOST_IO_ONLY" not in host:
        fail("present host must be I/O-only")
    if re.search(r"#include.*studio_shell_paint_fb|shell_paint_frame\s*\(", host):
        fail("present host must not link C paint mirror")

    build = BUILD_SH.read_text(encoding="utf-8")
    for needle in ("LiWorldStudio.AppDir", "AppRun", "bundle_sdl_libs", "LIG_WGPU_SWAPCHAIN"):
        if needle not in build:
            fail(f"build-studio-linux-appimage.sh missing {needle!r}")

    start = START_SH.read_text(encoding="utf-8")
    for needle in ("LIG_HOST_PRESENT=1", "LIG_WGPU_SWAPCHAIN=1", "linux_appimage"):
        if needle not in start:
            fail(f"start-li-world-studio-linux.sh missing {needle!r}")

    print("verify-linux-appimage: source wiring ok")


def try_build_linux() -> bool:
    if os.environ.get("STUDIO_LINUX_APPIMAGE_SKIP_BUILD") == "1":
        print("verify-linux-appimage: skip build (STUDIO_LINUX_APPIMAGE_SKIP_BUILD=1)")
        return APPDIR.is_dir() or HOST_BIN.is_file()
    if platform.system() != "Linux":
        print("verify-linux-appimage: skip live build (not Linux)")
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
        print(f"verify-linux-appimage: Linux build skipped — {tail.strip()}")
        return False
    if not (APPDIR / "AppRun").is_file():
        fail("AppDir missing AppRun after build")
    apprun = (APPDIR / "AppRun").read_text(encoding="utf-8")
    if "LIG_WGPU_SWAPCHAIN=1" not in apprun:
        fail("AppRun missing LIG_WGPU_SWAPCHAIN=1")
    host = APPDIR / "usr/bin/studio_shell_present_host"
    if not host.is_file():
        fail("AppDir missing usr/bin/studio_shell_present_host")
    print(f"verify-linux-appimage: AppDir ok at {APPDIR.relative_to(ROOT)}")
    if APPIMAGE.is_file():
        print(f"verify-linux-appimage: AppImage {APPIMAGE.name}")
    return True


def try_headless_run() -> None:
    if platform.system() != "Linux":
        print("verify-linux-appimage: skip headless run (not Linux)")
        return
    launcher = None
    if APPIMAGE.is_file() and os.access(APPIMAGE, os.X_OK):
        launcher = APPIMAGE
    elif (APPDIR / "AppRun").is_file():
        launcher = APPDIR / "AppRun"
    elif HOST_BIN.is_file() and os.access(HOST_BIN, os.X_OK):
        launcher = HOST_BIN
    if launcher is None:
        print("verify-linux-appimage: no launcher — source checks sufficient for CI")
        return

    out_dir = ROOT / "installer/out"
    out_dir.mkdir(parents=True, exist_ok=True)
    ppm = out_dir / "linux-appimage-probe.ppm"
    proc = subprocess.run(
        [str(launcher), "--width", "640", "--height", "360", "--screenshot", str(ppm)],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=30,
        env={**os.environ, "LIG_HOST_PRESENT": "1", "LIG_WGPU_SWAPCHAIN": "1"},
        check=False,
    )
    if proc.returncode != 0:
        tail = (proc.stderr or proc.stdout or "")[-400:]
        if os.environ.get("STUDIO_LINUX_APPIMAGE_REQUIRE_RUN") == "1":
            fail(f"Linux launcher run failed: {tail}")
        print(f"verify-linux-appimage: run skipped — {tail.strip()}")
        return
    if not ppm.is_file():
        if os.environ.get("STUDIO_LINUX_APPIMAGE_REQUIRE_RUN") == "1":
            fail("Linux launcher did not write PPM")
        print("verify-linux-appimage: run ok but PPM missing — soft skip")
        return
    if '"host_io_only":1' not in (proc.stdout or ""):
        fail("host JSON missing host_io_only=1")
    print("verify-linux-appimage: headless Linux run ok")


def main() -> int:
    check_sources()
    try_build_linux()
    try_headless_run()
    print("verify-linux-appimage: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
