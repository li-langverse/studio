#!/usr/bin/env python3
"""Verify World Studio viewport/UI perf budgets are documented and aligned (wsg-w5-perf-budgets).

Source checks always run. Live GPU bench is optional (soft-skip when hooks missing).
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RELEASE = ROOT / "docs/release-notes/2026-06-01-wsg-w5-perf-budgets.md"
TOKENS = ROOT / "docs/design/studio-design-tokens.toml"
REGISTRY = ROOT / "benchmarks/competitive/studio-ui.toml"
LIB_LI = ROOT / "src/lib.li"
LI_TOML = ROOT / "li.toml"
LATEST_BENCH = ROOT / "data/studio-ui-ux-plan-loop/latest-bench.json"
COMPETITIVE = ROOT / "benchmarks/results/bench-studio-viewport-perf.json"
CHANGELOG = ROOT / "CHANGELOG.md"
INSTALLER_README = ROOT / "installer/README.md"

EXPECTED = {
    "viewport_fps": 60,
    "panel_switch_ms": 100,
    "studio_load_ms": 2000,
    "memory_mib": 512,
    "md_1k_fps": 60,
    "md_10k_fps": 60,
    "md_100k_fps": 30,
}


def fail(msg: str) -> None:
    print(f"verify-perf-budgets: {msg}", file=sys.stderr)
    sys.exit(1)


def load_toml(path: Path) -> dict:
    import tomllib

    return tomllib.loads(path.read_text(encoding="utf-8"))


def check_release_notes() -> None:
    if not RELEASE.is_file():
        fail(f"missing {RELEASE.relative_to(ROOT)}")
    text = RELEASE.read_text(encoding="utf-8")
    for label, val in (
        ("Viewport FPS", EXPECTED["viewport_fps"]),
        ("Panel switch", EXPECTED["panel_switch_ms"]),
        ("Cold studio load", EXPECTED["studio_load_ms"]),
        ("512", EXPECTED["memory_mib"]),
    ):
        if label not in text:
            fail(f"release notes missing section/label {label!r}")
        if str(val) not in text:
            fail(f"release notes missing target value {val} for {label!r}")
    for needle in (
        "studio_perf_budgets_version",
        "bench-studio-viewport-perf.sh",
        "studio-design-tokens.toml",
    ):
        if needle not in text:
            fail(f"release notes missing {needle!r}")
    print("verify-perf-budgets: release notes ok")


def check_tokens() -> None:
    if not TOKENS.is_file():
        fail(f"missing {TOKENS.relative_to(ROOT)}")
    ph = load_toml(TOKENS).get("ph_ux") or {}
    mapping = {
        "viewport_fps_target": EXPECTED["viewport_fps"],
        "panel_switch_ms_max": EXPECTED["panel_switch_ms"],
        "studio_load_ms_max": EXPECTED["studio_load_ms"],
    }
    for key, want in mapping.items():
        got = ph.get(key)
        if got is None:
            fail(f"studio-design-tokens.toml [ph_ux].{key} missing")
        if int(got) != want:
            fail(f"tokens {key}={got} != {want}")
    print("verify-perf-budgets: design tokens ok")


def check_registry() -> None:
    if not REGISTRY.is_file():
        fail(f"missing {REGISTRY.relative_to(ROOT)}")
    reg = load_toml(REGISTRY)
    meta = reg.get("meta") or {}
    if meta.get("schema") != "li_studio_ui_bench_v1":
        fail("registry meta.schema must be li_studio_ui_bench_v1")
    gate_map = {g["id"]: g for g in reg.get("gate") or [] if isinstance(g, dict) and "id" in g}
    for gid, want in (
        ("viewport_fps", EXPECTED["viewport_fps"]),
        ("panel_switch_ms", EXPECTED["panel_switch_ms"]),
        ("studio_load_ms", EXPECTED["studio_load_ms"]),
    ):
        g = gate_map.get(gid)
        if not g:
            fail(f"registry missing [[gate]] id={gid}")
        if int(g.get("target", -1)) != want:
            fail(f"registry gate {gid} target {g.get('target')} != {want}")
    tiers = {t["id"]: t for t in reg.get("particle_tier") or [] if isinstance(t, dict) and "id" in t}
    for tid, want_fps in (
        ("md_1k", EXPECTED["md_1k_fps"]),
        ("md_10k", EXPECTED["md_10k_fps"]),
        ("md_100k", EXPECTED["md_100k_fps"]),
    ):
        t = tiers.get(tid)
        if not t:
            fail(f"registry missing [[particle_tier]] id={tid}")
        if int(t.get("fps_target", -1)) != want_fps:
            fail(f"registry tier {tid} fps_target != {want_fps}")
    mem = next((m for m in reg.get("memory") or [] if m.get("id") == "animate_md_import"), None)
    if not mem:
        fail("registry missing [[memory]] id=animate_md_import")
    if int(mem.get("warn_peak_mib", -1)) != EXPECTED["memory_mib"]:
        fail(f"registry memory warn_peak_mib != {EXPECTED['memory_mib']}")
    print("verify-perf-budgets: bench registry ok")


def check_lib_li() -> None:
    if not LIB_LI.is_file():
        fail("missing src/lib.li")
    lib = LIB_LI.read_text(encoding="utf-8")
    for needle in (
        "def studio_perf_budgets_version",
        "def studio_viewport_fps_budget",
        "def studio_panel_switch_ms_budget",
        "def studio_load_ms_budget",
        "def studio_memory_warn_peak_mib_budget",
        "def studio_perf_budgets_smoke",
        "wsg-w5-perf-budgets",
    ):
        if needle not in lib:
            fail(f"src/lib.li missing {needle!r}")
    print("verify-perf-budgets: lib.li perf budget API ok")


def check_li_toml() -> None:
    if not LI_TOML.is_file():
        fail("missing li.toml")
    text = LI_TOML.read_text(encoding="utf-8")
    m = re.search(r"panel_switch_budget_ms\s*=\s*(\d+)", text)
    if not m:
        fail("li.toml missing panel_switch_budget_ms")
    if int(m.group(1)) != EXPECTED["panel_switch_ms"]:
        fail(f"li.toml panel_switch_budget_ms != {EXPECTED['panel_switch_ms']}")
    print("verify-perf-budgets: li.toml metadata ok")


def check_bench_json(path: Path, label: str) -> None:
    if not path.is_file():
        print(f"verify-perf-budgets: skip {label} (missing {path.name})")
        return
    data = json.loads(path.read_text(encoding="utf-8"))
    for key, attr in (
        ("viewport_fps_target", EXPECTED["viewport_fps"]),
        ("panel_switch_ms_target", EXPECTED["panel_switch_ms"]),
        ("studio_load_ms_target", EXPECTED["studio_load_ms"]),
    ):
        got = data.get(key)
        if got is not None and int(got) != attr:
            fail(f"{label}: {key}={got} != {attr}")
    gates = data.get("gates") or {}
    for gid, want in (
        ("viewport_fps", EXPECTED["viewport_fps"]),
        ("panel_switch_ms", EXPECTED["panel_switch_ms"]),
        ("studio_load_ms", EXPECTED["studio_load_ms"]),
    ):
        g = gates.get(gid) or {}
        if g.get("target") is not None and int(g["target"]) != want:
            fail(f"{label}: gates.{gid}.target != {want}")
    print(f"verify-perf-budgets: {label} targets ok")


def check_changelog_installer() -> None:
    if not CHANGELOG.is_file():
        fail("missing CHANGELOG.md")
    if "wsg-w5-perf-budgets" not in CHANGELOG.read_text(encoding="utf-8"):
        fail("CHANGELOG.md missing wsg-w5-perf-budgets entry")
    if INSTALLER_README.is_file():
        readme = INSTALLER_README.read_text(encoding="utf-8", errors="replace")
        if "2026-06-01-wsg-w5-perf-budgets" not in readme and "perf budget" not in readme.lower():
            fail("installer/README.md must link perf budgets release notes")
    print("verify-perf-budgets: changelog + installer readme ok")


def main() -> int:
    check_release_notes()
    check_tokens()
    check_registry()
    check_lib_li()
    check_li_toml()
    check_bench_json(LATEST_BENCH, "latest-bench")
    check_bench_json(COMPETITIVE, "competitive-bench")
    check_changelog_installer()
    print("verify-perf-budgets: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
