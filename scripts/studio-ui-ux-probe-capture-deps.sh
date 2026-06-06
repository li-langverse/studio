#!/usr/bin/env bash
# Probe capture toolchain (SDL/Xvfb/Chrome/ffmpeg/gh) for proactive sweep + gates.
# Writes data/studio-ui-ux-plan-loop/latest-capture-deps.json (no secrets).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${STUDIO_UI_UX_CAPTURE_DEPS_JSON:-$ROOT/data/studio-ui-ux-plan-loop/latest-capture-deps.json}"
mkdir -p "$(dirname "$OUT")"

python3 - "$ROOT" "$OUT" <<'PY'
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

root = Path(sys.argv[1])
out = Path(sys.argv[2])


def has_cmd(name: str) -> bool:
    return shutil.which(name) is not None


def pkg_config(name: str) -> bool:
    if not has_cmd("pkg-config"):
        return False
    return subprocess.run(["pkg-config", "--exists", name], capture_output=True).returncode == 0


def find_chrome() -> str | None:
    for c in ("google-chrome", "chromium", "chromium-browser"):
        if has_cmd(c):
            return c
    return None


chrome = find_chrome()
sdl2 = pkg_config("sdl2")
xvfb = has_cmd("xvfb-run") or has_cmd("Xvfb")
display = bool(os.environ.get("DISPLAY"))
ffmpeg = has_cmd("ffmpeg")
gh = has_cmd("gh")
gh_token = bool(os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN"))
vulkan = pkg_config("vulkan") if has_cmd("pkg-config") else False
nvidia_smi = has_cmd("nvidia-smi")
wgpu_swapchain_env = os.environ.get("LIG_WGPU_SWAPCHAIN", "") == "1"

gaps: list[str] = []
if not sdl2:
    gaps.append("libsdl2-dev (pkg-config sdl2)")
if not xvfb and not display:
    gaps.append("xvfb-run or DISPLAY for headless SDL")
if not chrome:
    gaps.append("chromium/google-chrome for HTML mock PNG capture")
if not ffmpeg:
    gaps.append("ffmpeg for iter-reel MP4")
if not gh:
    gaps.append("gh CLI for issue/release upload")
elif not gh_token:
    gaps.append("GH_TOKEN for release upload")
if not vulkan and not nvidia_smi:
    gaps.append("Vulkan pkg-config or nvidia-smi for wgpu swapchain GPU CI (studio-ux-19)")

ready_native = sdl2 and (xvfb or display)
ready_wgpu_swapchain = (vulkan or nvidia_smi) and wgpu_swapchain_env
ready_html = chrome is not None

payload = {
    "schema": "li_studio_capture_deps_v1",
    "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "deps": {
        "sdl2": {"present": sdl2, "probe": "pkg-config --exists sdl2"},
        "xvfb": {"present": xvfb, "probe": "xvfb-run|Xvfb"},
        "display": {"present": display, "value": os.environ.get("DISPLAY")},
        "chrome": {"present": chrome is not None, "binary": chrome},
        "ffmpeg": {"present": ffmpeg},
        "gh": {"present": gh, "token_set": gh_token},
        "vulkan": {"present": vulkan, "probe": "pkg-config --exists vulkan"},
        "nvidia_smi": {"present": nvidia_smi},
        "lig_wgpu_swapchain": {"env_set": wgpu_swapchain_env},
    },
    "ready_for_native_capture": ready_native,
    "ready_for_wgpu_swapchain": ready_wgpu_swapchain,
    "ready_for_html_capture": ready_html,
    "gaps": gaps,
    "notes": [
        "native_pixels requires SDL+Xvfb; HTML mocks remain labeled marketing-only (UX-14)",
        "release upload needs gh + GH_TOKEN when png_count > 0",
    ],
}
out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"studio-ui-ux-probe-capture-deps: ok -> {out}")
if gaps:
    print(f"studio-ui-ux-probe-capture-deps: gaps={len(gaps)} → {', '.join(gaps[:3])}{'…' if len(gaps) > 3 else ''}")
PY
