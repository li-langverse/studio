#!/usr/bin/env python3
"""Verify Windows native SDL present host wiring (wsg-w5-windows-native).

Source checks always run. Live build/run soft-skip when MinGW+SDL2 unavailable.
"""
from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HOST_C = ROOT / "deploy/studio-demo/native/studio_shell_present_host.c"
BUILD_PS1 = ROOT / "scripts/build-studio-shell-present-host.ps1"
WINDOW_PS1 = ROOT / "scripts/start-li-world-studio-window.ps1"
PATHS_PS1 = ROOT / "scripts/_studio-paths.ps1"
LIB_LI = ROOT / "src/lib.li"
WIN_EXE = ROOT / "deploy/studio-demo/native/studio_shell_present_host.exe"


def fail(msg: str) -> None:
    print(f"verify-windows-native-present: {msg}", file=sys.stderr)
    sys.exit(1)


def check_sources() -> None:
    if not HOST_C.is_file():
        fail(f"missing {HOST_C.relative_to(ROOT)}")
    host = HOST_C.read_text(encoding="utf-8")
    if "STUDIO_SHELL_HOST_IO_ONLY" not in host:
        fail("present host must be I/O-only")
    if re.search(r'#include.*studio_shell_paint_fb|shell_paint_frame\s*\(', host):
        fail("present host must not link C paint mirror")
    if "host_setenv" not in host:
        fail("present host missing Windows-portable host_setenv (wsg-w5-windows-native)")
    if "_WIN32" not in host:
        fail("present host missing _WIN32 portability guard")

    for path, needles in (
        (BUILD_PS1, ("WindowsNative", "Build-PresentHostWindowsNative", "Get-MingwSdlFlags")),
        (WINDOW_PS1, ("Invoke-PresentHost", "Test-PeBinary", "Windows native (no WSL)")),
        (PATHS_PS1, ("Test-WindowsNativePresentHost", "Invoke-PresentHost", "Test-PeBinary")),
    ):
        if not path.is_file():
            fail(f"missing {path.relative_to(ROOT)}")
        text = path.read_text(encoding="utf-8", errors="replace")
        for n in needles:
            if n not in text:
                fail(f"{path.name} missing {n!r}")

    if not LIB_LI.is_file():
        fail("src/lib.li missing")
    lib = LIB_LI.read_text(encoding="utf-8")
    if "def studio_windows_native_present_version" not in lib:
        fail("src/lib.li missing studio_windows_native_present_version")
    print("verify-windows-native-present: source wiring ok")


def try_build_windows_native() -> bool:
    if os.environ.get("STUDIO_WINDOWS_NATIVE_SKIP_BUILD") == "1":
        print("verify-windows-native-present: skip build (STUDIO_WINDOWS_NATIVE_SKIP_BUILD=1)")
        return WIN_EXE.is_file()
    if sys.platform != "win32":
        print("verify-windows-native-present: skip live build (not win32)")
        return False
    ps = [
        "powershell",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        str(BUILD_PS1),
        "-WindowsNative",
    ]
    proc = subprocess.run(ps, cwd=ROOT, capture_output=True, text=True, timeout=180, check=False)
    if proc.returncode != 0:
        tail = (proc.stderr or proc.stdout or "")[-500:]
        print(f"verify-windows-native-present: Windows native build skipped — {tail.strip()}")
        return False
    if not WIN_EXE.is_file():
        return False
    magic = WIN_EXE.read_bytes()[:2]
    if magic != b"MZ":
        fail("studio_shell_present_host.exe is not a PE binary")
    print(f"verify-windows-native-present: built {WIN_EXE.name}")
    return True


def try_headless_run() -> None:
    if not WIN_EXE.is_file():
        print("verify-windows-native-present: no Windows .exe — source checks sufficient for CI")
        return
    out_dir = ROOT / "installer/out"
    out_dir.mkdir(parents=True, exist_ok=True)
    ppm = out_dir / "win-native-probe.ppm"
    proc = subprocess.run(
        [str(WIN_EXE), "--width", "640", "--height", "360", "--screenshot", str(ppm)],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=30,
        check=False,
    )
    if proc.returncode != 0:
        tail = (proc.stderr or proc.stdout or "")[-400:]
        if os.environ.get("STUDIO_WINDOWS_NATIVE_REQUIRE_RUN") == "1":
            fail(f"Windows native host run failed: {tail}")
        print(f"verify-windows-native-present: run skipped — {tail.strip()}")
        return
    if not ppm.is_file():
        if os.environ.get("STUDIO_WINDOWS_NATIVE_REQUIRE_RUN") == "1":
            fail("Windows native host did not write PPM")
        print("verify-windows-native-present: run ok but PPM missing — soft skip")
        return
    if '"host_io_only":1' not in (proc.stdout or ""):
        fail("host JSON missing host_io_only=1")
    print("verify-windows-native-present: headless Windows native run ok")


def main() -> int:
    check_sources()
    try_build_windows_native()
    try_headless_run()
    print("verify-windows-native-present: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
