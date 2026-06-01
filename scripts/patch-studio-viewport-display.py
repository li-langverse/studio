#!/usr/bin/env python3
"""Apply PH-UX viewport display vertical slice to src/lib.li"""
from pathlib import Path

LIB = Path(__file__).resolve().parents[1] / "src/lib.li"
text = LIB.read_text()

EXTERN_BLOCK = """
# PH-UX viewport display — background / MD tier / biomol style (CPU paint_blit; not wgpu PDB).
extern proc li_rt_studio_viewport_display_bg() raises IO -> int
  requires true
  ensures result >= 0
  ensures result <= 2
  decreases 0

extern proc li_rt_studio_viewport_display_set_bg(bg: int) raises IO -> int
  requires bg >= 0
  requires bg <= 2
  ensures result >= 0
  ensures result <= 2
  decreases bg

extern proc li_rt_studio_viewport_display_particle_tier() raises IO -> int
  requires true
  ensures result >= -1
  ensures result <= 2
  decreases 0

extern proc li_rt_studio_viewport_display_set_particle_tier(tier_id: int) raises IO -> int
  requires tier_id >= -1
  requires tier_id <= 2
  ensures result >= -1
  ensures result <= 2
  decreases tier_id

extern proc li_rt_studio_viewport_display_biomol_style() raises IO -> int
  requires true
  ensures result >= 0
  ensures result <= 2
  decreases 0

extern proc li_rt_studio_viewport_display_set_biomol_style(style: int) raises IO -> int
  requires style >= 0
  requires style <= 2
  ensures result >= 0
  ensures result <= 2
  decreases style

extern proc li_rt_studio_viewport_display_reset_defaults(profile_id: int) raises IO -> int
  requires profile_id >= 0
  ensures result == 1
  decreases profile_id

"""

if "li_rt_studio_viewport_display_bg" not in text:
    text = text.replace(
        "extern proc li_rt_studio_viewport_error_retry() raises IO -> int\n"
        "  requires true\n"
        "  ensures result >= 0\n"
        "  decreases 0\n\n"
        "# PH-HW WP3",
        "extern proc li_rt_studio_viewport_error_retry() raises IO -> int\n"
        "  requires true\n"
        "  ensures result >= 0\n"
        "  decreases 0\n"
        + EXTERN_BLOCK
        + "# PH-HW WP3",
    )

MCP_BLOCK = """
def studio_mcp_set_viewport_background() -> int
  requires true
  ensures result == 9
  decreases 0
=
  return 9

def studio_mcp_set_particle_display() -> int
  requires true
  ensures result == 10
  decreases 0
=
  return 10

def studio_mcp_set_biomol_style() -> int
  requires true
  ensures result == 11
  decreases 0
=
  return 11

"""

if "studio_mcp_set_viewport_background" not in text:
    text = text.replace(
        "def studio_mcp_studio_adaptive_layout() -> int\n"
        "  requires true\n"
        "  ensures result == 8\n"
        "  decreases 0\n"
        "=\n"
        "  return 8\n\n"
        "def studio_mcp_tool_count() -> int\n"
        "  requires true\n"
        "  ensures result == 8\n"
        "  decreases 0\n"
        "=\n"
        "  return 8\n",
        "def studio_mcp_studio_adaptive_layout() -> int\n"
        "  requires true\n"
        "  ensures result == 8\n"
        "  decreases 0\n"
        "=\n"
        "  return 8\n\n"
        + MCP_BLOCK
        + "def studio_mcp_tool_count() -> int\n"
        "  requires true\n"
        "  ensures result == 11\n"
        "  decreases 0\n"
        "=\n"
        "  return 11\n",
    )
    text = text.replace(
        "  if tool_id == studio_mcp_studio_adaptive_layout():\n"
        "    return 1\n"
        "  return 0\n\n"
        "def studio_mcp_tool_from_name(name: str)",
        "  if tool_id == studio_mcp_studio_adaptive_layout():\n"
        "    return 1\n"
        "  if tool_id == studio_mcp_set_viewport_background():\n"
        "    return 1\n"
        "  if tool_id == studio_mcp_set_particle_display():\n"
        "    return 1\n"
        "  if tool_id == studio_mcp_set_biomol_style():\n"
        "    return 1\n"
        "  return 0\n\n"
        "def studio_mcp_tool_from_name(name: str)",
    )

DISPATCH_AND_CORE = r'''
def studio_mcp_tool_dispatch(tool_id: int) -> StudioAgentToolRequest
  requires true
  ensures result.tool_id == tool_id
  decreases tool_id
=
  return studio_mcp_tool_dispatch_arg(tool_id, studio_mcp_tool_result_ok())

def studio_mcp_tool_dispatch_arg(tool_id: int, arg: int) -> StudioAgentToolRequest raises IO
  requires true
  ensures result.tool_id == tool_id
  decreases tool_id
=
  var out: StudioAgentToolRequest = studio_agent_tool_request_none()
  out.tool_id = tool_id
  if studio_mcp_tool_id_valid(tool_id) != 1:
    out.status = studio_mcp_tool_status_failed()
    out.result_code = studio_mcp_tool_result_err_io()
    return out
  if tool_id == studio_mcp_set_viewport_background():
    var bg: int = arg
    if bg < studio_viewport_bg_solid():
      bg = studio_viewport_bg_solid()
    if bg > studio_viewport_bg_gradient():
      bg = studio_viewport_bg_gradient()
    out.result_code = li_rt_studio_viewport_display_set_bg(bg)
    out.status = studio_mcp_tool_status_ok()
    return out
  if tool_id == studio_mcp_set_particle_display():
    var tier: int = arg
    if tier < studio_particle_display_off():
      tier = studio_particle_display_off()
    if tier > scene_md_tier_100k():
      tier = scene_md_tier_100k()
    out.result_code = li_rt_studio_viewport_display_set_particle_tier(tier)
    out.status = studio_mcp_tool_status_ok()
    return out
  if tool_id == studio_mcp_set_biomol_style():
    var style: int = arg
    if style < studio_biomol_style_cartoon():
      style = studio_biomol_style_cartoon()
    if style > studio_biomol_style_sticks():
      style = studio_biomol_style_sticks()
    out.result_code = li_rt_studio_viewport_display_set_biomol_style(style)
    out.status = studio_mcp_tool_status_ok()
    return out
  out.status = studio_mcp_tool_status_ok()
  out.result_code = studio_mcp_tool_result_ok()
  return out

def studio_viewport_bg_solid() -> int
  requires true
  ensures result == 0
  decreases 0
=
  return 0

def studio_viewport_bg_grid() -> int
  requires true
  ensures result == 1
  decreases 0
=
  return 1

def studio_viewport_bg_gradient() -> int
  requires true
  ensures result == 2
  decreases 0
=
  return 2

def studio_particle_display_off() -> int
  requires true
  ensures result == -1
  decreases 0
=
  return -1

def studio_biomol_style_cartoon() -> int
  requires true
  ensures result == 0
  decreases 0
=
  return 0

def studio_biomol_style_surface() -> int
  requires true
  ensures result == 1
  decreases 0
=
  return 1

def studio_biomol_style_sticks() -> int
  requires true
  ensures result == 2
  decreases 0
=
  return 2

def studio_viewport_display_read_bg() raises IO -> int
  requires true
  ensures result >= studio_viewport_bg_solid()
  ensures result <= studio_viewport_bg_gradient()
  decreases 0
=
  return li_rt_studio_viewport_display_bg()

def studio_viewport_display_read_particle_tier() raises IO -> int
  requires true
  ensures result >= studio_particle_display_off()
  ensures result <= scene_md_tier_100k()
  decreases 0
=
  return li_rt_studio_viewport_display_particle_tier()

def studio_viewport_display_read_biomol_style() raises IO -> int
  requires true
  ensures result >= studio_biomol_style_cartoon()
  ensures result <= studio_biomol_style_sticks()
  decreases 0
=
  return li_rt_studio_viewport_display_biomol_style()

def studio_viewport_display_reset_for_profile(profile_id: int) raises IO -> unit
  requires studio_profile_id_valid(profile_id) == 1
  ensures true
  decreases profile_id
=
  var _ok: int = li_rt_studio_viewport_display_reset_defaults(profile_id)

def studio_viewport_display_profile_wants_scene(profile_id: int) -> int
  requires studio_profile_id_valid(profile_id) == 1
  ensures result >= 0
  ensures result <= 1
  decreases profile_id
=
  if profile_id == studio_profile_sim_scientific():
    return 1
  if profile_id == studio_profile_sim_drug_design():
    return 1
  return 0

def studio_viewport_menu_btn_width_px() -> float
  requires true
  ensures result == 72.0
  decreases 0
=
  return 72.0

def studio_viewport_menu_btn_height_px() -> float
  requires true
  ensures result == 22.0
  decreases 0
=
  return 22.0

def studio_viewport_menu_btn_rect_at(vp: Rect, slot: int) -> Rect
  requires vp.w >= studio_viewport_menu_btn_width_px() * 3.0 + 32.0
  requires vp.h >= studio_viewport_menu_btn_height_px() + 16.0
  requires slot >= 0
  requires slot <= 2
  ensures result.w == studio_viewport_menu_btn_width_px()
  ensures result.h == studio_viewport_menu_btn_height_px()
  decreases slot
=
  var pad: float = 12.0
  var gap: float = 6.0
  var x: float = vp.x + pad + (studio_viewport_menu_btn_width_px() + gap) * slot
  var y: float = vp.y + pad
  return rect_make(x, y, studio_viewport_menu_btn_width_px(), studio_viewport_menu_btn_height_px())

def studio_viewport_display_tier_label_rect(vp: Rect) -> Rect
  requires vp.w >= 120.0
  requires vp.h >= 24.0
  ensures result.w >= 80.0
  decreases 0
=
  return rect_make(vp.x + 12.0, vp.y + vp.h - 28.0, 120.0, 16.0)

def studio_viewport_display_biomol_chip_rect(vp: Rect) -> Rect
  requires vp.w >= 96.0
  requires vp.h >= 24.0
  ensures result.w == 88.0
  ensures result.h == 18.0
  decreases 0
=
  return rect_make(vp.x + vp.w - 100.0, vp.y + vp.h - 28.0, 88.0, 18.0)

def studio_viewport_display_particle_dot_rect_at(vp: Rect, index: int) -> Rect
  requires vp.w >= 64.0
  requires vp.h >= 64.0
  requires index >= 0
  requires index < studio_viewport_display_particle_dot_count()
  ensures result.w == 6.0
  ensures result.h == 6.0
  decreases index
=
  var cols: int = 4
  var row: int = index / cols
  var col: int = index - (row * cols)
  var cx: float = vp.x + vp.w * 0.35 + col * 14.0
  var cy: float = vp.y + vp.h * 0.42 + row * 14.0
  return rect_make(cx, cy, 6.0, 6.0)

def studio_viewport_display_particle_dot_count() -> int
  requires true
  ensures result == 8
  decreases 0
=
  return 8

type StudioViewportDisplayCompose = object
  public background: int
  public particle_tier_id: int
  public biomol_style: int
  public tier_particles: int
  public tier_label_rect: Rect
  public biomol_chip_rect: Rect
  public particle_dots_visible: int

type StudioViewportMenuCompose = object
  public menu_visible: int
  public bg_btn: Rect
  public particle_btn: Rect
  public biomol_btn: Rect

def studio_viewport_display_compose_new() -> StudioViewportDisplayCompose
  requires true
  ensures result.background == studio_viewport_bg_solid()
  ensures result.particle_tier_id == studio_particle_display_off()
  decreases 0
=
  var d: StudioViewportDisplayCompose
  d.background = studio_viewport_bg_solid()
  d.particle_tier_id = studio_particle_display_off()
  d.biomol_style = studio_biomol_style_cartoon()
  d.tier_particles = 0
  d.tier_label_rect = rect_make(0.0, 0.0, 0.0, 0.0)
  d.biomol_chip_rect = rect_make(0.0, 0.0, 0.0, 0.0)
  d.particle_dots_visible = 0
  return d

def studio_viewport_menu_compose_new() -> StudioViewportMenuCompose
  requires true
  ensures result.menu_visible == 0
  decreases 0
=
  var m: StudioViewportMenuCompose
  m.menu_visible = 0
  m.bg_btn = rect_make(0.0, 0.0, 0.0, 0.0)
  m.particle_btn = rect_make(0.0, 0.0, 0.0, 0.0)
  m.biomol_btn = rect_make(0.0, 0.0, 0.0, 0.0)
  return m

def studio_compose_viewport_display(vp: Rect, profile_id: int) raises IO -> StudioViewportDisplayCompose
  requires vp.w >= 0.0
  requires vp.h >= 0.0
  requires studio_profile_id_valid(profile_id) == 1
  decreases profile_id
=
  var out: StudioViewportDisplayCompose = studio_viewport_display_compose_new()
  out.background = studio_viewport_display_read_bg()
  out.particle_tier_id = studio_viewport_display_read_particle_tier()
  out.biomol_style = studio_viewport_display_read_biomol_style()
  out.tier_label_rect = studio_viewport_display_tier_label_rect(vp)
  out.biomol_chip_rect = studio_viewport_display_biomol_chip_rect(vp)
  if out.particle_tier_id >= scene_md_tier_1k():
    var tier: SceneMdParticleTier = scene_md_particle_tier_by_id(out.particle_tier_id)
    out.tier_particles = tier.particles
    out.particle_dots_visible = 1
  return out

def studio_compose_viewport_menu(vp: Rect, profile_id: int) -> StudioViewportMenuCompose
  requires vp.w >= 0.0
  requires vp.h >= 0.0
  requires studio_profile_id_valid(profile_id) == 1
  decreases profile_id
=
  var out: StudioViewportMenuCompose = studio_viewport_menu_compose_new()
  if studio_viewport_display_profile_wants_scene(profile_id) != 1:
    return out
  out.menu_visible = 1
  out.bg_btn = studio_viewport_menu_btn_rect_at(vp, 0)
  out.particle_btn = studio_viewport_menu_btn_rect_at(vp, 1)
  out.biomol_btn = studio_viewport_menu_btn_rect_at(vp, 2)
  return out

def studio_attach_viewport_shell(compose: var StudioShellCompose) raises IO -> unit
  requires studio_profile_id_valid(compose.config.active_profile) == 1
  ensures true
  decreases 0
=
  var pid: int = compose.config.active_profile
  compose.viewport_display = studio_compose_viewport_display(compose.layout.viewport, pid)
  compose.viewport_menu = studio_compose_viewport_menu(compose.layout.viewport, pid)

'''

if "studio_mcp_tool_dispatch_arg" not in text:
    import re

    text = re.sub(
        r"def studio_mcp_tool_dispatch\(tool_id: int\) -> StudioAgentToolRequest\n"
        r"  requires true\n"
        r"  ensures result\.tool_id == tool_id\n"
        r"  decreases tool_id\n"
        r"=\n"
        r"  var out: StudioAgentToolRequest = studio_agent_tool_request_none\(\)\n"
        r"  out\.tool_id = tool_id\n"
        r"  if studio_mcp_tool_id_valid\(tool_id\) != 1:\n"
        r"    out\.status = studio_mcp_tool_status_failed\(\)\n"
        r"    out\.result_code = studio_mcp_tool_result_err_io\(\)\n"
        r"    return out\n"
        r"  out\.status = studio_mcp_tool_status_ok\(\)\n"
        r"  out\.result_code = studio_mcp_tool_result_ok\(\)\n"
        r"  return out\n",
        DISPATCH_AND_CORE.strip() + "\n",
        text,
        count=1,
    )

if "public viewport_display:" not in text:
    text = text.replace(
        "  public viewport_error: StudioViewportErrorOverlay\n"
        "  public agent: StudioAgentChromeCompose\n",
        "  public viewport_error: StudioViewportErrorOverlay\n"
        "  public viewport_display: StudioViewportDisplayCompose\n"
        "  public viewport_menu: StudioViewportMenuCompose\n"
        "  public agent: StudioAgentChromeCompose\n",
    )

PAINT_BLOCK = r'''
def studio_paint_viewport_display_bg_cmds(background: int) -> int
  requires background >= studio_viewport_bg_solid()
  requires background <= studio_viewport_bg_gradient()
  ensures result >= 0
  ensures result <= 2
  decreases background
=
  if background == studio_viewport_bg_gradient():
    return 2
  if background == studio_viewport_bg_solid():
    return 1
  return 0

def studio_paint_viewport_display_cmds(display: StudioViewportDisplayCompose) -> int
  requires display.background >= studio_viewport_bg_solid()
  requires display.background <= studio_viewport_bg_gradient()
  ensures result >= 0
  decreases display.background
=
  var n: int = studio_paint_viewport_display_bg_cmds(display.background)
  if display.particle_dots_visible == 1:
    n = n + studio_viewport_display_particle_dot_count()
  if display.tier_particles > 0:
    n = n + 1
  n = n + 1
  return n

def studio_paint_viewport_menu_cmds(menu: StudioViewportMenuCompose) -> int
  requires true
  ensures result >= 0
  ensures result <= 3
  decreases menu.menu_visible
=
  if menu.menu_visible != 1:
    return 0
  return 3

def studio_viewport_display_bg_color(background: int) -> Color
  requires background >= studio_viewport_bg_solid()
  requires background <= studio_viewport_bg_gradient()
  ensures result.r >= 0.0
  decreases background
=
  if background == studio_viewport_bg_gradient():
    return color_rgb(0.04, 0.06, 0.12, 1.0)
  if background == studio_viewport_bg_grid():
    return color_rgb(0.05, 0.07, 0.10, 1.0)
  return color_rgb(0.051, 0.067, 0.090, 1.0)

def studio_viewport_display_biomol_color(style: int) -> Color
  requires style >= studio_biomol_style_cartoon()
  requires style <= studio_biomol_style_sticks()
  ensures result.r >= 0.0
  decreases style
=
  if style == studio_biomol_style_surface():
    return studio_color_accent_violet()
  if style == studio_biomol_style_sticks():
    return studio_color_accent_mint()
  return studio_color_accent_cyan()

def studio_paint_viewport_display_dot(frame: var PaintFrame, vp: Rect, index: int) -> unit
  requires frame.cmd_count >= 0
  requires index >= 0
  requires index < studio_viewport_display_particle_dot_count()
  ensures frame.cmd_count == old(frame.cmd_count) + 1
  decreases index
=
  var dot: Rect = studio_viewport_display_particle_dot_rect_at(vp, index)
  frame.cmd_count = frame.cmd_count + 1
  frame.last_kind = paint_op_fill_rect()
  frame.last_rect = dot
  frame.last_color = studio_color_accent_amber()

def studio_paint_viewport_display(frame: var PaintFrame, vp: Rect, display: StudioViewportDisplayCompose) -> unit
  requires frame.cmd_count >= 0
  requires vp.w >= 0.0
  requires vp.h >= 0.0
  ensures frame.cmd_count == old(frame.cmd_count) + studio_paint_viewport_display_cmds(display)
  decreases display.background
=
  var bg_n: int = studio_paint_viewport_display_bg_cmds(display.background)
  if bg_n >= 1:
    frame.cmd_count = frame.cmd_count + 1
    frame.last_kind = paint_op_fill_rect()
    frame.last_rect = vp
    frame.last_color = studio_viewport_display_bg_color(display.background)
  if display.background == studio_viewport_bg_gradient():
    frame.cmd_count = frame.cmd_count + 1
    frame.last_kind = paint_op_fill_rect()
    var band: Rect = rect_make(vp.x, vp.y, vp.w, vp.h * 0.35)
    frame.last_rect = band
    frame.last_color = color_rgb(0.08, 0.10, 0.18, 1.0)
  if display.particle_dots_visible == 1:
    studio_paint_viewport_display_dot(frame, vp, 0)
    studio_paint_viewport_display_dot(frame, vp, 1)
    studio_paint_viewport_display_dot(frame, vp, 2)
    studio_paint_viewport_display_dot(frame, vp, 3)
    studio_paint_viewport_display_dot(frame, vp, 4)
    studio_paint_viewport_display_dot(frame, vp, 5)
    studio_paint_viewport_display_dot(frame, vp, 6)
    studio_paint_viewport_display_dot(frame, vp, 7)
  if display.tier_particles > 0:
    frame.cmd_count = frame.cmd_count + 1
    frame.last_kind = paint_op_fill_rect()
    frame.last_rect = display.tier_label_rect
    frame.last_color = studio_color_border()
  frame.cmd_count = frame.cmd_count + 1
  frame.last_kind = paint_op_stroke_rect()
  frame.last_rect = display.biomol_chip_rect
  frame.last_color = studio_viewport_display_biomol_color(display.biomol_style)

def studio_paint_viewport_menu(frame: var PaintFrame, menu: StudioViewportMenuCompose) -> unit
  requires frame.cmd_count >= 0
  ensures frame.cmd_count == old(frame.cmd_count) + studio_paint_viewport_menu_cmds(menu)
  decreases menu.menu_visible
=
  if menu.menu_visible != 1:
    return
  frame.cmd_count = frame.cmd_count + 1
  frame.last_kind = paint_op_stroke_rect()
  frame.last_rect = menu.bg_btn
  frame.last_color = studio_color_accent_cyan()
  frame.cmd_count = frame.cmd_count + 1
  frame.last_kind = paint_op_stroke_rect()
  frame.last_rect = menu.particle_btn
  frame.last_color = studio_color_accent_amber()
  frame.cmd_count = frame.cmd_count + 1
  frame.last_kind = paint_op_stroke_rect()
  frame.last_rect = menu.biomol_btn
  frame.last_color = studio_color_accent_violet()

'''

if "studio_paint_viewport_display_bg_cmds" not in text:
    text = text.replace(
        "def studio_paint_viewport_scene_cmds() -> int\n"
        "  requires true\n"
        "  ensures result == 1\n"
        "  decreases 0\n"
        "=\n"
        "  return 1\n\n\n"
        "def studio_paint_dock(frame: var PaintFrame, dock: StudioDockCompose) -> unit\n",
        "def studio_paint_viewport_scene_cmds() -> int\n"
        "  requires true\n"
        "  ensures result == 1\n"
        "  decreases 0\n"
        "=\n"
        "  return 1\n\n"
        + PAINT_BLOCK
        + "def studio_paint_dock(frame: var PaintFrame, dock: StudioDockCompose) -> unit\n",
    )

text = text.replace(
    "def studio_shell_viewport_cmds(scene_entity_count: int, viewport_error_kind: int) -> int\n"
    "  requires scene_entity_count >= 0\n"
    "  requires viewport_error_kind >= studio_viewport_error_none()\n"
    "  requires viewport_error_kind <= studio_err_missing_asset()\n"
    "  ensures result >= 1\n"
    "  ensures result <= 3\n"
    "  decreases viewport_error_kind\n"
    "=\n"
    "  if studio_viewport_error_visible(viewport_error_kind) == 1:\n"
    "    return studio_paint_viewport_error_cmds()\n"
    "  if scene_entity_count == 0:\n"
    "    return studio_paint_viewport_empty_cmds()\n"
    "  return studio_paint_viewport_scene_cmds()\n",
    "def studio_shell_viewport_cmds(scene_entity_count: int, viewport_error_kind: int, display: StudioViewportDisplayCompose, menu: StudioViewportMenuCompose) -> int\n"
    "  requires scene_entity_count >= 0\n"
    "  requires viewport_error_kind >= studio_viewport_error_none()\n"
    "  requires viewport_error_kind <= studio_err_missing_asset()\n"
    "  ensures result >= 1\n"
    "  decreases viewport_error_kind\n"
    "=\n"
    "  if studio_viewport_error_visible(viewport_error_kind) == 1:\n"
    "    return studio_paint_viewport_error_cmds()\n"
    "  if scene_entity_count == 0:\n"
    "    return studio_paint_viewport_empty_cmds()\n"
    "  return studio_paint_viewport_scene_cmds() + studio_paint_viewport_display_cmds(display) + studio_paint_viewport_menu_cmds(menu)\n",
)

text = text.replace(
    "  return studio_paint_compose_panels_count(sel0) + 1 + studio_paint_topbar_profile_cmds() + studio_shell_viewport_cmds(scene0, viewport_error_kind) + studio_paint_agent_cmds(ts0, ctx0) + studio_paint_palette_cmds(pal0)\n",
    "  return studio_paint_compose_panels_count(sel0) + 1 + studio_paint_topbar_profile_cmds() + studio_shell_viewport_cmds(scene0, viewport_error_kind, display, menu) + studio_paint_agent_cmds(ts0, ctx0) + studio_paint_palette_cmds(pal0)\n",
)

text = text.replace(
    "def studio_shell_chrome_count_palette(has_selection: int, scene_entity_count: int, task_state: int, palette_open: int, agent_context_label: int, viewport_error_kind: int) -> int\n",
    "def studio_shell_chrome_count_palette(has_selection: int, scene_entity_count: int, task_state: int, palette_open: int, agent_context_label: int, viewport_error_kind: int, display: StudioViewportDisplayCompose, menu: StudioViewportMenuCompose) -> int\n",
)

text = text.replace(
    "  return studio_shell_chrome_count_palette(sel_palette, scene0, ts0, studio_palette_closed_flag(), studio_agent_context_for_shell(sel_ctx, ts0), studio_viewport_error_none())\n",
    "  var disp0: StudioViewportDisplayCompose = studio_viewport_display_compose_new()\n"
    "  var menu0: StudioViewportMenuCompose = studio_viewport_menu_compose_new()\n"
    "  return studio_shell_chrome_count_palette(sel_palette, scene0, ts0, studio_palette_closed_flag(), studio_agent_context_for_shell(sel_ctx, ts0), studio_viewport_error_none(), disp0, menu0)\n",
)

text = text.replace(
    "  ensures frame.cmd_count == studio_shell_chrome_count_palette(compose.inspector.has_selection, compose.scene_entity_count, compose.agent.task_state, compose.palette.is_open, compose.agent.agent_context_label, compose.viewport_error.error_kind)\n",
    "  ensures frame.cmd_count == studio_shell_chrome_count_palette(compose.inspector.has_selection, compose.scene_entity_count, compose.agent.task_state, compose.palette.is_open, compose.agent.agent_context_label, compose.viewport_error.error_kind, compose.viewport_display, compose.viewport_menu)\n",
)

text = text.replace(
    "      frame.last_color = studio_color_accent_cyan()\n"
    "  studio_paint_agent(frame, compose.agent)\n"
    "  paint_studio_palette(frame, compose.palette)\n",
    "      frame.last_color = studio_color_accent_cyan()\n"
    "      studio_paint_viewport_display(frame, compose.layout.viewport, compose.viewport_display)\n"
    "      studio_paint_viewport_menu(frame, compose.viewport_menu)\n"
    "  studio_paint_agent(frame, compose.agent)\n"
    "  paint_studio_palette(frame, compose.palette)\n",
)

for old_end in (
    "  out.loading = studio_shell_loading_state_new()\n  return out\n\n\ndef studio_compose_shell_loading",
    "  out.loading = studio_shell_loading_state_new()\n  return out\n\n\ndef studio_compose_shell(w:",
):
    new_end = old_end.replace(
        "  out.loading = studio_shell_loading_state_new()\n  return out\n",
        "  out.loading = studio_shell_loading_state_new()\n"
        "  studio_attach_viewport_shell(out)\n"
        "  return out\n",
    )
    if old_end in text:
        text = text.replace(old_end, new_end, 1)

text = text.replace(
    "  if has_selection == 1:\n"
    "    out.inspector.field_rows = studio_drug_litl_inspector_field_rows(stage)\n"
    "  return out\n\n"
    "def li_std_studio_version() -> int\n"
    "  requires true\n"
    "  ensures result == 8\n"
    "  decreases 0\n"
    "=\n"
    "  return 8\n",
    "  if has_selection == 1:\n"
    "    out.inspector.field_rows = studio_drug_litl_inspector_field_rows(stage)\n"
    "  studio_viewport_display_reset_for_profile(studio_profile_sim_drug_design())\n"
    "  out.scene_entity_count = 1\n"
    "  out.viewport_empty.empty_visible = 0\n"
    "  studio_attach_viewport_shell(out)\n"
    "  return out\n\n"
    "def li_std_studio_version() -> int\n"
    "  requires true\n"
    "  ensures result == 9\n"
    "  decreases 0\n"
    "=\n"
    "  return 9\n",
)

text = text.replace(
    "  studio_shell_demo_apply_profile(out, profile_id)\n  return out\n\n"
    "def studio_vertical_demo_frame(profile_id: int, frame_id: int) -> int raises IO\n",
    "  studio_shell_demo_apply_profile(out, profile_id)\n"
    "  if studio_viewport_display_profile_wants_scene(profile_id) == 1:\n"
    "    studio_viewport_display_reset_for_profile(profile_id)\n"
    "    out.scene_entity_count = 1\n"
    "    out.viewport_empty.empty_visible = 0\n"
    "    studio_attach_viewport_shell(out)\n"
    "  return out\n\n"
    "def studio_vertical_demo_frame(profile_id: int, frame_id: int) -> int raises IO\n",
)

LIB.write_text(text)
print("patched", LIB)
