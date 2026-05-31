#!/usr/bin/env python3
"""Verify native present host uses styled chrome (round rects + gradients), not wireframe-only."""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PAINT_C = ROOT / "deploy/studio-demo/native/studio_shell_paint_fb.c"
HOST_BIN = ROOT / "deploy/studio-demo/native/studio_shell_present_host"
OUT_DIR = ROOT / "installer/out"
PPM_PATH = OUT_DIR / "styled-chrome-verify.ppm"


def fail(msg: str) -> None:
    print(f"studio-ui-ux-verify-styled-chrome-native: {msg}", file=sys.stderr)
    sys.exit(1)


def check_source() -> None:
    if not PAINT_C.is_file():
        fail(f"missing {PAINT_C.relative_to(ROOT)}")
    text = PAINT_C.read_text(encoding="utf-8")
    for needle in ("fill_round_rect", "stroke_round_rect", "fill_gradient_v"):
        if needle not in text:
            fail(f"C paint mirror missing {needle}")
    if "fill_round_rect(rgb, width, height, layout.agent_strip" not in text:
        fail("agent strip must use fill_round_rect (styled chrome)")
    print("studio-ui-ux-verify-styled-chrome-native: C mirror has round-rect + gradient ops")


def read_ppm_rgb(path: Path) -> tuple[int, int, list[int]]:
    data = path.read_bytes()
    if len(data) < 8:
        fail(f"PPM too small: {path}")
    magic = data[:2].decode("ascii", errors="replace")
    if magic not in ("P3", "P6"):
        fail(f"unsupported PPM magic {magic!r}: {path}")
    pos = 2
    while pos < len(data) and data[pos] in b" \t\r\n#":
        if data[pos] == ord("#"):
            while pos < len(data) and data[pos] != ord("\n"):
                pos += 1
        pos += 1
    def next_token() -> bytes:
        nonlocal pos
        while pos < len(data) and data[pos] in b" \t\r\n":
            pos += 1
        start = pos
        while pos < len(data) and data[pos] not in b" \t\r\n":
            pos += 1
        return data[start:pos]

    w = int(next_token())
    h = int(next_token())
    _maxv = int(next_token())
    if magic == "P3":
        vals = [int(x) for x in data[pos:].decode("ascii").split()]
    else:
        body = data[pos:]
        if len(body) < w * h * 3:
            fail(f"P6 body truncated: {path}")
        vals = list(body[: w * h * 3])
    return w, h, vals


def sample_corner_gradient(path: Path) -> None:
    w, h, rgb = read_ppm_rgb(path)
    if w < 64 or h < 64:
        fail(f"PPM too small for corner probe: {w}x{h}")
    # Topbar gradient: row under top edge should differ from mid-topbar row at same x.
    x = min(200, w - 1)
    y_top = 4
    y_mid = 20
    idx = lambda xx, yy: (yy * w + xx) * 3

    def lum(i: int) -> int:
        return rgb[i] + rgb[i + 1] + rgb[i + 2]

    l_top = lum(idx(x, y_top))
    l_mid = lum(idx(x, y_mid))
    if l_top == l_mid:
        fail("topbar lacks vertical gradient (wireframe flat fill?)")
    # Dock active slot uses accent cyan — sample near dock center.
    cx, cy = 28, 28
    i = idx(cx, cy)
    if rgb[i] < 40 and rgb[i + 1] < 150:
        fail("dock active slot missing accent cyan fill")
    print(f"studio-ui-ux-verify-styled-chrome-native: PPM probe ok ({w}x{h})")


def wsl_path(p: Path) -> str:
    s = str(p.resolve()).replace("\\", "/")
    if len(s) >= 2 and s[1] == ":":
        return f"/mnt/{s[0].lower()}{s[2:]}"
    return s


def host_runnable() -> bool:
    if not HOST_BIN.is_file():
        return False
    if sys.platform == "win32":
        try:
            with HOST_BIN.open("rb") as f:
                magic = f.read(4)
            # ELF/Linux binary — run via WSL, not CreateProcess on Windows.
            if magic[:4] == b"\x7fELF":
                return shutil.which("wsl") is not None
        except OSError:
            return False
    return os.access(HOST_BIN, os.X_OK)


def try_screenshot() -> None:
    if os.environ.get("STUDIO_UI_UX_VERIFY_SKIP_NATIVE_RUN") == "1":
        print("studio-ui-ux-verify-styled-chrome-native: skip run (STUDIO_UI_UX_VERIFY_SKIP_NATIVE_RUN=1)")
        return
    if not HOST_BIN.is_file():
        print("studio-ui-ux-verify-styled-chrome-native: present host not built — source check only")
        return
    if not host_runnable():
        print("studio-ui-ux-verify-styled-chrome-native: present host not runnable here — source check only")
        return
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    ppm = PPM_PATH
    host = str(HOST_BIN)
    out_ppm = str(ppm)
    if sys.platform == "win32" and HOST_BIN.read_bytes()[:4] == b"\x7fELF":
        host = wsl_path(HOST_BIN)
        out_ppm = wsl_path(ppm)
        cmd = [
            "wsl",
            "-e",
            "bash",
            "-lc",
            f"'{host}' --width 640 --height 360 --screenshot '{out_ppm}'",
        ]
    else:
        cmd = [host, "--width", "640", "--height", "360", "--screenshot", out_ppm]
    proc = subprocess.run(
        cmd,
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=90,
        check=False,
    )
    if proc.returncode != 0:
        print(proc.stderr[-600:] if proc.stderr else proc.stdout)
        fail(f"present host screenshot exit {proc.returncode}")
    if not ppm.is_file():
        fail(f"screenshot missing {ppm.name}")
    sample_corner_gradient(ppm)


def main() -> int:
    check_source()
    try_screenshot()
    print("studio-ui-ux-verify-styled-chrome-native: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
