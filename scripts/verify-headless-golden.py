#!/usr/bin/env python3
"""Verify wsg-w4-headless-golden: Li CPU raster PPM path (no studio_shell_paint_fb.c)."""
from __future__ import annotations

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIC_ROOT = Path(os.environ.get("LIC_ROOT", ROOT.parent / "lic"))
LIB = LIC_ROOT / "packages" / "li-studio" / "src" / "lib.li"
RT = LIC_ROOT / "runtime" / "li_rt_studio_headless_raster.c"
PAINT_FB = LIC_ROOT / "runtime" / "li_rt_studio_paint_capture.c"
FIXTURES = ROOT / "fixtures" / "headless-golden"


def fail(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


def ok(msg: str) -> None:
    print(f"OK: {msg}")


def main() -> int:
    if not LIB.is_file():
        fail(f"missing {LIB}")
    text = LIB.read_text(encoding="utf-8")
    for sym in (
        "def studio_headless_golden_frame",
        "def studio_vertical_capture_ppm",
        "li_rt_studio_headless_raster_ppm",
    ):
        if sym not in text:
            fail(f"li-studio missing {sym}")
    ok("li-studio headless golden API")

    if not RT.is_file():
        fail(f"missing {RT}")
    rt = RT.read_text(encoding="utf-8")
    if "studio_shell_paint_fb" in rt:
        fail("headless raster runtime must not include paint_fb mirror")
    ok("li_rt_studio_headless_raster.c has no paint_fb")

    if PAINT_FB.is_file():
        if "studio_shell_paint_fb.c" in PAINT_FB.read_text(encoding="utf-8"):
            ok("C paint_fb fenced in li_rt_studio_paint_capture (not product headless path)")

    manifest = FIXTURES / "manifest.toml"
    if not manifest.is_file():
        fail(f"missing {manifest}")
    ok("headless-golden fixtures manifest")

    print("verify-headless-golden: pass")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
