#!/usr/bin/env python3
"""Verify studio-design-tokens.toml matches packages/li-ui/src/lib.li (LIC_ROOT sibling)."""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOKENS = ROOT / "docs/design/studio-design-tokens.toml"


def resolve_palette() -> Path:
    lic_root = os.environ.get("LIC_ROOT")
    if lic_root:
        candidate = Path(lic_root) / "packages/li-ui/src/lib.li"
        if candidate.is_file():
            return candidate
    for sibling in (
        ROOT.parent / "lic",
        ROOT.parent.parent / "lic",
        ROOT / "packages/li-ui/src/lib.li",
    ):
        if sibling.is_file():
            return sibling
        candidate = sibling / "packages/li-ui/src/lib.li"
        if candidate.is_file():
            return candidate
    return ROOT / "packages/li-ui/src/lib.li"


PALETTE = resolve_palette()
STUDIO_LIB = ROOT / "src/lib.li"

# TOML [color] key -> lib.li studio token function name
COLOR_MAP = {
    "bg_primary": "studio_color_bg_primary",
    "bg_elevated": "studio_color_bg_elevated",
    "border": "studio_color_border",
    "text_primary": "studio_color_text_primary",
    "text_muted": "studio_color_text_muted",
    "accent_cyan": "studio_color_accent_cyan",
    "accent_violet": "studio_color_accent_violet",
    "accent_mint": "studio_color_accent_mint",
    "accent_amber": "studio_color_accent_amber",
    "accent_rose": "studio_color_accent_rose",
    "agent_running": "studio_color_agent_running",
    "agent_idle": "studio_color_agent_idle",
    "agent_error": "studio_color_agent_error",
    "focus_ring": "studio_color_focus_ring",
    "viewport_grid": "studio_color_viewport_grid",
}

ELEVATION_FLOAT_MAP = {
    "shadow_alpha_base": ("studio_elevation_shadow_alpha_base", "elevation"),
    "shadow_layer_count": ("studio_elevation_shadow_layer_count", "elevation"),
    "shadow_offset_base_px": ("studio_elevation_shadow_offset_base_px", "elevation"),
    "shadow_spread_px": ("studio_elevation_shadow_spread_px", "elevation"),
    "shadow_alpha_falloff": ("studio_elevation_shadow_alpha_falloff", "elevation"),
}

FX_FLOAT_MAP = {
    "opacity_disabled": ("studio_fx_opacity_disabled", "fx"),
    "opacity_scrim": ("studio_fx_opacity_scrim", "fx"),
    "opacity_hover_delta": ("studio_fx_opacity_hover_delta", "fx"),
    "blur_sigma_px": ("studio_fx_blur_sigma_px", "fx"),
    "blur_radius_px": ("studio_fx_blur_radius_px", "fx"),
}

FX_INT_MAP = {
    "blur_passes": ("studio_fx_blur_passes", "fx"),
}

VIEWPORT_FLOAT_MAP = {
    "hud_chip_height_px": ("studio_viewport_hud_chip_height_px", "viewport"),
    "menu_chip_inset_px": ("studio_viewport_menu_chip_inset_px", "viewport"),
    "tier_chip_width_px": ("studio_viewport_tier_chip_width_px", "viewport"),
    "biomol_chip_width_px": ("studio_viewport_biomol_chip_width_px", "viewport"),
}

DENSITY_FLOAT_MAP = {
    "dock_slot_size_px": ("studio_density_dock_slot_size_px", "density"),
    "dock_slot_gap_px": ("studio_density_dock_slot_gap_px", "density"),
    "dock_padding_px": ("studio_density_dock_padding_px", "density"),
    "dock_icon_inset_px": ("studio_density_dock_icon_inset_px", "density"),
    "topbar_tool_size_px": ("studio_density_topbar_tool_size_px", "density"),
    "topbar_tool_gap_px": ("studio_density_topbar_tool_gap_px", "density"),
    "timeline_play_icon_inset_px": ("studio_density_timeline_play_icon_inset_px", "density"),
}

FLOAT_MAP = {
    "dock_width_px": ("studio_dock_width_px", "spacing"),
    "outliner_width_px": ("studio_outliner_width_px", "spacing"),
    "topbar_height_px": ("studio_topbar_height_px", "spacing"),
    "inspector_width_px": ("studio_inspector_width_px", "spacing"),
    "panel_transition_ms": ("studio_panel_transition_ms", "motion"),
    "hover_transition_ms": ("studio_hover_transition_ms", "motion"),
    "dock_label_px": ("studio_typography_dock_label_px", "typography"),
    "caption_px": ("studio_typography_caption_px", "typography"),
    "body_px": ("studio_typography_body_px", "typography"),
    "heading_px": ("studio_typography_heading_px", "typography"),
    "sm_px": ("studio_radius_sm_px", "radius"),
    "md_px": ("studio_radius_md_px", "radius"),
    "lg_px": ("studio_radius_lg_px", "radius"),
    "pill_px": ("studio_radius_pill_px", "radius"),
}

STRING_LEN_MAP = {
    "ui": ("studio_typography_ui_family_len", "typography"),
    "mono": ("studio_typography_mono_family_len", "typography"),
}

ICON_LEN_MAP = {
    "dock_scene": ("studio_icon_token_id_dock_scene", "studio_icon_token_name_len"),
    "dock_assets": ("studio_icon_token_id_dock_assets", "studio_icon_token_name_len"),
    "dock_sim": ("studio_icon_token_id_dock_sim", "studio_icon_token_name_len"),
    "dock_timeline": ("studio_icon_token_id_dock_timeline", "studio_icon_token_name_len"),
    "dock_settings": ("studio_icon_token_id_dock_settings", "studio_icon_token_name_len"),
}


def hex_to_rgb(hex_str: str) -> tuple[float, float, float]:
    h = hex_str.lstrip("#")
    if len(h) != 6:
        raise ValueError(hex_str)
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return r / 255.0, g / 255.0, b / 255.0


def strip_toml_comment(line: str) -> str:
    in_quote = False
    quote = ""
    for i, ch in enumerate(line):
        if ch in ('"', "'") and (i == 0 or line[i - 1] != "\\"):
            if not in_quote:
                in_quote = True
                quote = ch
            elif ch == quote:
                in_quote = False
        elif ch == "#" and not in_quote:
            return line[:i].strip()
    return line.strip()


def parse_toml_section(path: Path, want: str) -> dict[str, str]:
    section = ""
    out: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = strip_toml_comment(raw)
        if not line:
            continue
        m = re.match(r"\[([^\]]+)\]", line)
        if m:
            section = m.group(1)
            continue
        if "=" not in line or section != want:
            continue
        key, _, val = line.partition("=")
        out[key.strip()] = val.strip().strip('"').strip("'")
    return out


def parse_palette_rgb(path: Path, fn: str) -> tuple[float, float, float]:
    block = path.read_text(encoding="utf-8")
    pat = rf"def {re.escape(fn)}\(\)[\s\S]*?return color_rgb\(([^)]+)\)"
    m = re.search(pat, block)
    if not m:
        raise KeyError(fn)
    parts = [float(x.strip()) for x in m.group(1).split(",")[:3]]
    return parts[0], parts[1], parts[2]


def parse_palette_float(path: Path, fn: str) -> float:
    block = path.read_text(encoding="utf-8")
    pat = rf"def {re.escape(fn)}\(\)[\s\S]*?return ([0-9.]+)"
    m = re.search(pat, block)
    if not m:
        raise KeyError(fn)
    return float(m.group(1))


def parse_palette_int(path: Path, fn: str) -> int:
    block = path.read_text(encoding="utf-8")
    pat = rf"def {re.escape(fn)}\(\)[\s\S]*?return ([0-9]+)"
    m = re.search(pat, block)
    if not m:
        raise KeyError(fn)
    return int(m.group(1))


def main() -> int:
    if not TOKENS.is_file():
        print(f"error: missing {TOKENS}", file=sys.stderr)
        return 1
    if not PALETTE.is_file():
        print(f"error: missing {PALETTE} (set LIC_ROOT)", file=sys.stderr)
        return 1

    colors = parse_toml_section(TOKENS, "color")
    tol = 1.0 / 255.0
    errors: list[str] = []

    for key, fn in COLOR_MAP.items():
        hex_val = colors.get(key)
        if not hex_val:
            errors.append(f"missing TOML color.{key}")
            continue
        expected = hex_to_rgb(hex_val)
        actual = parse_palette_rgb(PALETTE, fn)
        for i, label in enumerate("rgb"):
            if abs(expected[i] - actual[i]) > tol:
                errors.append(
                    f"{fn} {label}: palette {actual[i]:.4f} != TOML {hex_val} ({expected[i]:.4f})"
                )

    sections = {
        "spacing": parse_toml_section(TOKENS, "spacing"),
        "motion": parse_toml_section(TOKENS, "motion"),
        "typography": parse_toml_section(TOKENS, "typography"),
        "radius": parse_toml_section(TOKENS, "radius"),
        "elevation": parse_toml_section(TOKENS, "elevation"),
        "fx": parse_toml_section(TOKENS, "fx"),
        "viewport": parse_toml_section(TOKENS, "viewport"),
        "density": parse_toml_section(TOKENS, "density"),
    }

    if STUDIO_LIB.is_file():
        for key, (fn, section) in FX_FLOAT_MAP.items():
            raw = sections[section].get(key)
            if raw is None:
                errors.append(f"missing TOML {section}.{key}")
                continue
            tom = float(raw)
            try:
                actual = parse_palette_float(STUDIO_LIB, fn)
            except KeyError:
                errors.append(f"missing studio {fn} in {STUDIO_LIB}")
                continue
            if actual != tom:
                errors.append(f"{fn}: studio {actual} != TOML {tom}")

        for key, (fn, section) in FX_INT_MAP.items():
            raw = sections[section].get(key)
            if raw is None:
                errors.append(f"missing TOML {section}.{key}")
                continue
            tom = int(raw)
            try:
                actual = parse_palette_int(STUDIO_LIB, fn)
            except KeyError:
                errors.append(f"missing studio {fn} in {STUDIO_LIB}")
                continue
            if actual != tom:
                errors.append(f"{fn}: studio {actual} != TOML {tom}")

        for key, (fn, section) in ELEVATION_FLOAT_MAP.items():
            raw = sections[section].get(key)
            if raw is None:
                errors.append(f"missing TOML {section}.{key}")
                continue
            tom = float(raw)
            try:
                actual = parse_palette_float(STUDIO_LIB, fn)
            except KeyError:
                errors.append(f"missing studio {fn} in {STUDIO_LIB}")
                continue
            if key == "shadow_layer_count":
                actual_i = parse_palette_int(STUDIO_LIB, fn)
                if actual_i != int(tom):
                    errors.append(f"{fn}: studio {actual_i} != TOML {int(tom)}")
            elif actual != tom:
                errors.append(f"{fn}: studio {actual} != TOML {tom}")

        for key, (fn, section) in VIEWPORT_FLOAT_MAP.items():
            raw = sections[section].get(key)
            if raw is None:
                errors.append(f"missing TOML {section}.{key}")
                continue
            tom = float(raw)
            try:
                actual = parse_palette_float(STUDIO_LIB, fn)
            except KeyError:
                errors.append(f"missing studio {fn} in {STUDIO_LIB}")
                continue
            if actual != tom:
                errors.append(f"{fn}: studio {actual} != TOML {tom}")

        for key, (fn, section) in DENSITY_FLOAT_MAP.items():
            raw = sections[section].get(key)
            if raw is None:
                errors.append(f"missing TOML {section}.{key}")
                continue
            tom = float(raw)
            try:
                actual = parse_palette_float(STUDIO_LIB, fn)
            except KeyError:
                errors.append(f"missing studio {fn} in {STUDIO_LIB}")
                continue
            if actual != tom:
                errors.append(f"{fn}: studio {actual} != TOML {tom}")

    for key, (fn, section) in FLOAT_MAP.items():
        raw = sections[section].get(key)
        if raw is None:
            errors.append(f"missing TOML {section}.{key}")
            continue
        tom = float(raw)
        actual = parse_palette_float(PALETTE, fn)
        if actual != tom:
            errors.append(f"{fn}: palette {actual} != TOML {tom}")

    for key, (fn, section) in STRING_LEN_MAP.items():
        raw = sections[section].get(key)
        if raw is None:
            errors.append(f"missing TOML {section}.{key}")
            continue
        expected_len = len(raw)
        actual = parse_palette_int(PALETTE, fn)
        if actual != expected_len:
            errors.append(f"{fn}: palette {actual} != TOML string len {expected_len}")

    icons = parse_toml_section(TOKENS, "icons")
    for key, (token_id_fn, name_len_fn) in ICON_LEN_MAP.items():
        raw = icons.get(key)
        if raw is None:
            errors.append(f"missing TOML icons.{key}")
            continue
        if raw != key:
            errors.append(f"icons.{key}: value {raw!r} must match token key {key!r}")
        expected_len = len(raw)
        block = PALETTE.read_text(encoding="utf-8")
        pat_if = rf"if token_id == {re.escape(token_id_fn)}\(\):\s+return ([0-9]+)"
        m = re.search(pat_if, block)
        if not m:
            errors.append(f"missing {name_len_fn} branch for {token_id_fn}")
            continue
        actual = int(m.group(1))
        if actual != expected_len:
            errors.append(f"{name_len_fn}({token_id_fn}): palette {actual} != TOML len {expected_len}")
    if icons and parse_palette_int(PALETTE, "icon_atlas_slot_count") != len(icons):
        errors.append("icon_atlas_slot_count != len(TOML [icons])")

    if errors:
        for e in errors:
            print(f"studio-ui-ux-verify-tokens: {e}", file=sys.stderr)
        return 1

    print(f"studio-ui-ux-verify-tokens: ok (TOML <-> {PALETTE.name})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
