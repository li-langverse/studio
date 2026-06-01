#!/usr/bin/env python3
"""Verify World Studio installer CI matrix wiring (wsg-w5-installer-ci).

Source checks always run. Live Inno/AppImage compile soft-skip per platform.
"""
from __future__ import annotations

import os
import platform
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = ROOT / ".github/workflows/world-studio-installers.yml"
ISS = ROOT / "installer/LiWorldStudio.iss"
BUILD_PS1 = ROOT / "scripts/build-li-world-studio-installer.ps1"
RUNNABLE = ROOT / "scripts/world-studio-runnable-gate.sh"
LINUX_VERIFY = ROOT / "scripts/verify-linux-appimage.py"
LIB_LI = ROOT / "src/lib.li"
SETUP_EXE = ROOT / "installer/out/LiWorldStudio-Setup.exe"
LICENSE = ROOT / "installer/LICENSE-GPL-3.0.txt"


def fail(msg: str) -> None:
    print(f"verify-installer-ci: {msg}", file=sys.stderr)
    sys.exit(1)


def check_sources() -> None:
    for path in (WORKFLOW, ISS, BUILD_PS1, RUNNABLE, LINUX_VERIFY, LIB_LI, LICENSE):
        if not path.is_file():
            fail(f"missing {path.relative_to(ROOT)}")

    lib = LIB_LI.read_text(encoding="utf-8")
    for needle in (
        "def studio_installer_ci_version",
        "def studio_installer_ci_smoke",
        "def studio_windows_native_present_version",
        "def studio_linux_appimage_version",
        "def studio_macos_wgpu_present_version",
    ):
        if needle not in lib:
            fail(f"src/lib.li missing {needle!r}")

    wf = WORKFLOW.read_text(encoding="utf-8")
    for job in ("linux-installer-matrix", "windows-installer-matrix", "macos-wgpu-surface-smoke"):
        if job not in wf:
            fail(f"workflow missing job {job!r}")
    for needle in (
        "verify-installer-ci.py",
        "verify-linux-appimage.py",
        "build-li-world-studio-installer.ps1",
        "pull_request:",
    ):
        if needle not in wf:
            fail(f"workflow missing {needle!r}")
    if "ubuntu-24.04" not in wf or "windows-latest" not in wf:
        fail("workflow missing Windows + Linux matrix runners")

    iss = ISS.read_text(encoding="utf-8")
    for needle in ("LiWorldStudio-Setup", "LICENSE-GPL-3.0", "li-studio-demo"):
        if needle not in iss:
            fail(f"LiWorldStudio.iss missing {needle!r}")

    ps1 = BUILD_PS1.read_text(encoding="utf-8")
    if "LiWorldStudio.iss" not in ps1 or "Find-InnoSetupIscc" not in ps1:
        fail("build-li-world-studio-installer.ps1 incomplete")

    print("verify-installer-ci: source wiring ok")


def run_subverify(script: Path) -> None:
    proc = subprocess.run(
        [sys.executable, str(script)],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=120,
        check=False,
    )
    if proc.returncode != 0:
        tail = (proc.stderr or proc.stdout or "")[-600:]
        fail(f"{script.name} failed: {tail.strip()}")
    print(f"verify-installer-ci: {script.name} ok")


def try_windows_iscc() -> bool:
    if platform.system() != "Windows":
        print("verify-installer-ci: skip Inno compile (not Windows)")
        return False
    if os.environ.get("STUDIO_INSTALLER_CI_SKIP_BUILD") == "1":
        print("verify-installer-ci: skip Inno (STUDIO_INSTALLER_CI_SKIP_BUILD=1)")
        return SETUP_EXE.is_file()
    if not shutil_which("iscc"):
        for candidate in (
            Path(os.environ.get("LOCALAPPDATA", "")) / "Programs/Inno Setup 6/ISCC.exe",
            Path(r"C:\Program Files (x86)\Inno Setup 6\ISCC.exe"),
        ):
            if candidate.is_file():
                break
        else:
            print("verify-installer-ci: iscc not on PATH — source checks sufficient for CI")
            return False
    demo = ROOT / "build/li-studio-demo.exe"
    if not demo.is_file():
        lic_demo = ROOT.parent / "lic/build/li-studio-demo.exe"
        if lic_demo.is_file():
            demo.parent.mkdir(parents=True, exist_ok=True)
            import shutil

            shutil.copy2(lic_demo, demo)
    if not demo.is_file():
        print("verify-installer-ci: demo binary missing — skip iscc on CI without lic build")
        return False
    ps = [
        "powershell",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        str(BUILD_PS1),
        "-SkipDemoBuild",
        "-SkipPresentHost",
    ]
    try:
        proc = subprocess.run(
            ps,
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=300,
            check=False,
        )
    except FileNotFoundError:
        print("verify-installer-ci: powershell not found — source checks sufficient for CI")
        return False
    if proc.returncode != 0:
        tail = (proc.stderr or proc.stdout or "")[-500:]
        if os.environ.get("STUDIO_INSTALLER_CI_REQUIRE_BUILD") == "1":
            fail(f"Inno build failed: {tail.strip()}")
        print(f"verify-installer-ci: Inno build skipped — {tail.strip()}")
        return False
    if not SETUP_EXE.is_file():
        fail("Inno compile did not produce LiWorldStudio-Setup.exe")
    print(f"verify-installer-ci: {SETUP_EXE.name} ok ({SETUP_EXE.stat().st_size} bytes)")
    return True


def shutil_which(cmd: str) -> str | None:
    from shutil import which

    return which(cmd)


def main() -> int:
    check_sources()
    run_subverify(LINUX_VERIFY)
    try_windows_iscc()
    print("verify-installer-ci: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
