/* Mirrors packages/li-ui layout_studio_shell_adaptive + li-studio studio_paint_shell_chrome. */
#include "studio_shell_paint_fb.h"

#include <string.h>

#define DOCK_W 56
#define TOPBAR_H 44
#define INSPECTOR_W 320
#define TIMELINE_H 180
#define AGENT_H 40
#define DOCK_SLOT 36
#define DOCK_GAP 8
#define DOCK_PAD 12
#define OUTLINER_GAP 10
#define OUTLINER_ROW_H 18
#define OUTLINER_ROW_GAP 4
#define TIMELINE_TRACK_H 48
#define TIMELINE_TRACK_PAD 12
#define INSPECTOR_HEADER_H 32
#define CHIP_W 88
#define CHIP_PAD 12

static const unsigned char k_bg_primary[] = {13, 17, 23};
static const unsigned char k_bg_elevated[] = {22, 27, 34};
static const unsigned char k_border[] = {48, 54, 61};
static const unsigned char k_accent_cyan[] = {61, 214, 255};
static const unsigned char k_accent_mint[] = {46, 230, 168};
static const unsigned char k_accent_amber[] = {255, 179, 71};
static const unsigned char k_accent_violet[] = {124, 92, 255};
static const unsigned char k_agent_idle[] = {48, 54, 61};
static const unsigned char k_panel_shadow[] = {8, 10, 14};
static const unsigned char k_text_primary[] = {230, 237, 243};
static const unsigned char k_text_muted[] = {139, 148, 158};
static const unsigned char k_text_dim[] = {96, 105, 115};
static const unsigned char k_hover_tint[] = {32, 38, 48};
static const unsigned char k_focus_ring[] = {61, 214, 255};

static const ShellProfileVisual k_profiles[] = {
    {1, "game", 21, 61, 214, 255},
    {2, "sim_rl", 22, 46, 230, 168},
    {3, "sim_automotive", 23, 255, 179, 71},
    {4, "sim_robotics", 24, 255, 179, 71},
    {5, "sim_additive", 25, 255, 179, 71},
    {6, "sim_scientific", 26, 255, 179, 71},
    {7, "sim_drug_design", 27, 124, 92, 255},
};

const ShellProfileVisual* shell_profile_find(int profile_id) {
  for (size_t i = 0; i < sizeof(k_profiles) / sizeof(k_profiles[0]); i++) {
    if (k_profiles[i].id == profile_id) {
      return &k_profiles[i];
    }
  }
  return NULL;
}

void shell_layout_adaptive(int width, int height, int inspector_w, ShellLayout* out) {
  int vp_w = width - DOCK_W - inspector_w;
  if (vp_w < 0) {
    vp_w = 0;
  }
  int vp_h = height - TOPBAR_H - TIMELINE_H - AGENT_H;
  if (vp_h < 0) {
    vp_h = 0;
  }
  int agent_y = TOPBAR_H + vp_h;
  int tl_w = width - DOCK_W - inspector_w;
  if (tl_w < 0) {
    tl_w = 0;
  }
  int agent_w = tl_w;
  out->dock = (ShellRect){0, 0, DOCK_W, height};
  out->topbar = (ShellRect){DOCK_W, 0, width - DOCK_W, TOPBAR_H};
  out->viewport = (ShellRect){DOCK_W, TOPBAR_H, vp_w, vp_h};
  out->inspector = (ShellRect){width - inspector_w, TOPBAR_H, inspector_w, height - TOPBAR_H};
  out->timeline = (ShellRect){DOCK_W, height - TIMELINE_H, tl_w, TIMELINE_H};
  out->agent_strip = (ShellRect){DOCK_W, agent_y, agent_w, AGENT_H};
}

static void put_px(unsigned char* rgb, int w, int h, int x, int y, const unsigned char* c) {
  if (x < 0 || y < 0 || x >= w || y >= h) {
    return;
  }
  unsigned char* p = rgb + (y * w + x) * 3;
  p[0] = c[0];
  p[1] = c[1];
  p[2] = c[2];
}

static void fill_rect(unsigned char* rgb, int w, int h, ShellRect r, const unsigned char* c) {
  int x1 = r.x + r.w;
  int y1 = r.y + r.h;
  for (int yy = r.y; yy < y1 && yy < h; yy++) {
    for (int xx = r.x; xx < x1 && xx < w; xx++) {
      put_px(rgb, w, h, xx, yy, c);
    }
  }
}

static void stroke_rect(unsigned char* rgb, int w, int h, ShellRect r, const unsigned char* c, int stroke) {
  if (stroke < 1) {
    stroke = 1;
  }
  for (int t = 0; t < stroke; t++) {
    ShellRect top = {r.x, r.y + t, r.w, 1};
    ShellRect bot = {r.x, r.y + r.h - 1 - t, r.w, 1};
    ShellRect left = {r.x + t, r.y, 1, r.h};
    ShellRect right = {r.x + r.w - 1 - t, r.y, 1, r.h};
    fill_rect(rgb, w, h, top, c);
    fill_rect(rgb, w, h, bot, c);
    fill_rect(rgb, w, h, left, c);
    fill_rect(rgb, w, h, right, c);
  }
}

static void stroke_vline(unsigned char* rgb, int w, int h, int x, int y0, int y1, const unsigned char* c) {
  if (y0 > y1) {
    int t = y0;
    y0 = y1;
    y1 = t;
  }
  for (int y = y0; y <= y1; y++) {
    put_px(rgb, w, h, x, y, c);
  }
}

static void stroke_hline(unsigned char* rgb, int w, int h, int x0, int x1, int y, const unsigned char* c) {
  if (x0 > x1) {
    int t = x0;
    x0 = x1;
    x1 = t;
  }
  for (int x = x0; x <= x1; x++) {
    put_px(rgb, w, h, x, y, c);
  }
}

static void fill_gradient_v(unsigned char* rgb, int w, int h, ShellRect r, const unsigned char* top,
                            const unsigned char* bot) {
  if (r.h <= 0 || r.w <= 0) {
    return;
  }
  for (int yy = r.y; yy < r.y + r.h && yy < h; yy++) {
    float t = (r.h > 1) ? (float)(yy - r.y) / (float)(r.h - 1) : 0.0f;
    unsigned char c[3];
    c[0] = (unsigned char)((1.0f - t) * (float)top[0] + t * (float)bot[0]);
    c[1] = (unsigned char)((1.0f - t) * (float)top[1] + t * (float)bot[1]);
    c[2] = (unsigned char)((1.0f - t) * (float)top[2] + t * (float)bot[2]);
    ShellRect row = {r.x, yy, r.w, 1};
    fill_rect(rgb, w, h, row, c);
  }
}

static void fill_round_rect(unsigned char* rgb, int w, int h, ShellRect r, const unsigned char* c, int radius) {
  if (radius < 1) {
    fill_rect(rgb, w, h, r, c);
    return;
  }
  ShellRect core = {r.x + radius, r.y, r.w - 2 * radius, r.h};
  if (core.w > 0) {
    fill_rect(rgb, w, h, core, c);
  }
  ShellRect cap_top = {r.x, r.y + radius, r.w, radius};
  ShellRect cap_bot = {r.x, r.y + r.h - radius, r.w, radius};
  if (cap_top.h > 0) {
    fill_rect(rgb, w, h, cap_top, c);
  }
  if (cap_bot.h > 0) {
    fill_rect(rgb, w, h, cap_bot, c);
  }
}

static void stroke_round_rect(unsigned char* rgb, int w, int h, ShellRect r, const unsigned char* c, int stroke,
                              int radius) {
  stroke_rect(rgb, w, h, r, c, stroke);
  if (radius > 0 && r.w > 2 * radius && r.h > 2 * radius) {
    ShellRect inner = {r.x + radius, r.y + radius, r.w - 2 * radius, r.h - 2 * radius};
    stroke_rect(rgb, w, h, inner, c, 1);
  }
}

static int dock_slot_offset_y(int slot) {
  int step = DOCK_SLOT + DOCK_GAP;
  return DOCK_PAD + slot * step;
}

static ShellRect dock_active_slot_rect(ShellRect dock, int slot) {
  int x = dock.x + (dock.w - DOCK_SLOT) / 2;
  int y = dock.y + dock_slot_offset_y(slot);
  return (ShellRect){x, y, DOCK_SLOT, DOCK_SLOT};
}

static ShellRect outliner_strip(ShellRect dock) {
  int top = dock.y + dock_slot_offset_y(4) + DOCK_SLOT + OUTLINER_GAP;
  int hh = dock.h - (top - dock.y);
  if (hh < 0) {
    hh = 0;
  }
  return (ShellRect){dock.x, top, dock.w, hh};
}

static ShellRect outliner_row(ShellRect strip, int row) {
  int step = OUTLINER_ROW_H + OUTLINER_ROW_GAP;
  return (ShellRect){strip.x + 6, strip.y + row * step, strip.w - 12, OUTLINER_ROW_H};
}

static ShellRect timeline_track(ShellRect timeline) {
  int y = timeline.y + timeline.h - TIMELINE_TRACK_H - TIMELINE_TRACK_PAD;
  return (ShellRect){timeline.x, y, timeline.w, TIMELINE_TRACK_H};
}

static ShellRect timeline_playhead(ShellRect track, float pct) {
  if (pct < 0.0f) {
    pct = 0.0f;
  }
  if (pct > 1.0f) {
    pct = 1.0f;
  }
  int px = track.x + (int)((float)track.w * pct);
  return (ShellRect){px, track.y, 2, track.h};
}

static ShellRect profile_chip(ShellRect topbar, int tag_h) {
  int chip_h = tag_h;
  if (chip_h < 20) {
    chip_h = 20;
  }
  int x = topbar.x + topbar.w - CHIP_W - CHIP_PAD;
  int y = topbar.y + (topbar.h - chip_h) / 2;
  return (ShellRect){x, y, CHIP_W, chip_h};
}

static void paint_viewport_grid(unsigned char* rgb, int w, int h, ShellRect vp) {
  for (int x = vp.x; x < vp.x + vp.w; x += 64) {
    unsigned char grid_c[3] = {
        (unsigned char)(k_border[0] + (x % 3)),
        (unsigned char)(k_border[1] + (x % 5)),
        (unsigned char)(k_border[2] + (x % 7)),
    };
    stroke_vline(rgb, w, h, x, vp.y, vp.y + vp.h - 1, grid_c);
  }
  for (int y = vp.y; y < vp.y + vp.h; y += 64) {
    unsigned char grid_c[3] = {
        (unsigned char)(k_border[0] + (y % 5)),
        (unsigned char)(k_border[1] + (y % 3)),
        (unsigned char)(k_border[2] + (y % 11)),
    };
    stroke_hline(rgb, w, h, vp.x, vp.x + vp.w - 1, y, grid_c);
  }
  int ox = vp.x + 48;
  int oy = vp.y + vp.h - 48;
  stroke_vline(rgb, w, h, ox, vp.y + 24, oy, k_accent_cyan);
  stroke_hline(rgb, w, h, ox, vp.x + vp.w - 24, oy, k_accent_cyan);
}

static void paint_panel_shadow(unsigned char* rgb, int w, int h, ShellRect panel, int offset) {
  ShellRect shadow = {panel.x + offset, panel.y + offset, panel.w, panel.h};
  fill_round_rect(rgb, w, h, shadow, k_panel_shadow, 6);
}

static void paint_glyph_bar(unsigned char* rgb, int w, int h, ShellRect bar, const unsigned char* base) {
  if (bar.w <= 0 || bar.h <= 0) {
    return;
  }
  for (int xx = bar.x; xx < bar.x + bar.w && xx < w; xx += 7) {
    unsigned char c[3] = {
        (unsigned char)(base[0] > 8 ? base[0] - (xx % 5) : base[0]),
        (unsigned char)(base[1] > 8 ? base[1] - (xx % 7) : base[1]),
        (unsigned char)(base[2] > 8 ? base[2] - (xx % 3) : base[2]),
    };
    ShellRect ch = {xx, bar.y, 5, bar.h};
    fill_rect(rgb, w, h, ch, c);
  }
}

static void paint_topbar_accent(unsigned char* rgb, int w, int h, ShellRect topbar, const unsigned char* accent) {
  ShellRect strip = {topbar.x, topbar.y, topbar.w, 3};
  fill_rect(rgb, w, h, strip, accent);
  ShellRect title = {topbar.x + 16, topbar.y + 14, topbar.w / 4, 12};
  paint_glyph_bar(rgb, w, h, title, k_text_primary);
  ShellRect sub = {title.x, title.y + 16, topbar.w / 5, 8};
  paint_glyph_bar(rgb, w, h, sub, k_text_muted);
}

static void paint_viewport_particles(unsigned char* rgb, int w, int h, ShellRect vp, const unsigned char* accent) {
  for (int i = 0; i < 64; i++) {
    int px = vp.x + 40 + (i * 37) % (vp.w > 80 ? vp.w - 80 : 1);
    int py = vp.y + 40 + (i * 53) % (vp.h > 80 ? vp.h - 80 : 1);
    unsigned char c[3] = {
        (unsigned char)((accent[0] + i * 3) % 256),
        (unsigned char)((accent[1] + i * 5) % 256),
        (unsigned char)((accent[2] + i * 7) % 256),
    };
    ShellRect dot = {px, py, 3 + (i % 4), 3 + (i % 3)};
    fill_round_rect(rgb, w, h, dot, c, 2);
  }
}

static void paint_viewport_game_blocks(unsigned char* rgb, int w, int h, ShellRect vp) {
  int cols = 6;
  int rows = 4;
  int bw = (vp.w - 80) / cols;
  int bh = (vp.h - 80) / rows;
  if (bw < 12) {
    bw = 12;
  }
  if (bh < 12) {
    bh = 12;
  }
  for (int row = 0; row < rows; row++) {
    for (int col = 0; col < cols; col++) {
      int x = vp.x + 40 + col * (bw + 8);
      int y = vp.y + 40 + row * (bh + 8);
      unsigned char c[3] = {
          (unsigned char)(40 + col * 28 + row * 11),
          (unsigned char)(80 + row * 22),
          (unsigned char)(120 + col * 18),
      };
      ShellRect block = {x, y, bw, bh};
      fill_round_rect(rgb, w, h, block, c, 4);
      stroke_round_rect(rgb, w, h, block, k_border, 1, 4);
    }
  }
}

static void paint_viewport_drug_sticks(unsigned char* rgb, int w, int h, ShellRect vp) {
  for (int i = 0; i < 12; i++) {
    int x = vp.x + 48 + i * 56;
    int base_y = vp.y + vp.h - 80;
    int stick_h = 40 + (i % 5) * 18;
    unsigned char c[3] = {
        (unsigned char)(100 + i * 12),
        (unsigned char)(60 + (i * 17) % 80),
        (unsigned char)(180 + (i * 9) % 60),
    };
    ShellRect stick = {x, base_y - stick_h, 18, stick_h};
    fill_round_rect(rgb, w, h, stick, c, 3);
  }
}

static void paint_viewport_hud(unsigned char* rgb, int w, int h, ShellRect vp, const char* mode_label) {
  (void)mode_label;
  ShellRect hud = {vp.x + vp.w - 168, vp.y + 12, 156, 52};
  fill_round_rect(rgb, w, h, hud, k_bg_elevated, 6);
  stroke_round_rect(rgb, w, h, hud, k_border, 1, 6);
  ShellRect mode = {hud.x + 10, hud.y + 10, hud.w - 20, 10};
  ShellRect sel = {hud.x + 10, hud.y + 26, hud.w - 20, 8};
  paint_glyph_bar(rgb, w, h, mode, k_text_primary);
  paint_glyph_bar(rgb, w, h, sel, k_accent_mint);
  ShellRect legend = {vp.x + 12, vp.y + vp.h - 36, 120, 24};
  fill_round_rect(rgb, w, h, legend, k_bg_elevated, 4);
  paint_glyph_bar(rgb, w, h, (ShellRect){legend.x + 8, legend.y + 8, 80, 8}, k_text_dim);
}

static void paint_viewport_profile(unsigned char* rgb, int w, int h, ShellRect vp, const ShellProfileVisual* profile) {
  paint_viewport_grid(rgb, w, h, vp);
  if (profile == NULL) {
    return;
  }
  unsigned char accent[3] = {profile->chip_r, profile->chip_g, profile->chip_b};
  if (profile->id == 1) {
    paint_viewport_game_blocks(rgb, w, h, vp);
  } else if (profile->id == 7) {
    paint_viewport_drug_sticks(rgb, w, h, vp);
  } else {
    paint_viewport_particles(rgb, w, h, vp, accent);
  }
  paint_viewport_hud(rgb, w, h, vp, profile->slug);
}

static void paint_inspector_selected(unsigned char* rgb, int w, int h, ShellRect insp) {
  fill_gradient_v(rgb, w, h, insp, k_bg_primary, k_bg_elevated);
  stroke_round_rect(rgb, w, h, insp, k_accent_violet, 2, 6);
  ShellRect header = {insp.x, insp.y, insp.w, INSPECTOR_HEADER_H};
  fill_round_rect(rgb, w, h, header, k_accent_violet, 4);
  ShellRect field = {insp.x + 12, insp.y + INSPECTOR_HEADER_H + 12, insp.w - 24, 20};
  fill_round_rect(rgb, w, h, field, k_bg_elevated, 4);
  paint_glyph_bar(rgb, w, h, (ShellRect){field.x + 6, field.y + 5, field.w - 12, 10}, k_text_primary);
  ShellRect val = {field.x, field.y + 28, field.w, 16};
  paint_glyph_bar(rgb, w, h, val, k_accent_violet);
}

static void paint_inspector_empty(unsigned char* rgb, int w, int h, ShellRect insp) {
  fill_gradient_v(rgb, w, h, insp, k_bg_primary, k_bg_elevated);
  stroke_round_rect(rgb, w, h, insp, k_border, 1, 6);
  ShellRect line1 = {insp.x + 12, insp.y + INSPECTOR_HEADER_H + 16, insp.w - 24, 10};
  ShellRect line2 = {insp.x + 12, line1.y + 18, insp.w - 24, 10};
  fill_round_rect(rgb, w, h, line1, k_bg_elevated, 4);
  fill_round_rect(rgb, w, h, line2, k_bg_elevated, 4);
  ShellRect box = {insp.x + 12, line2.y + 20, insp.w - 24, 48};
  stroke_round_rect(rgb, w, h, box, k_border, 1, 6);
}

void shell_paint_frame(unsigned char* rgb, int width, int height, const ShellProfileVisual* profile,
                       int has_selection, float playhead_pct) {
  ShellLayout layout;
  int insp_w = INSPECTOR_W;
  if (profile != NULL && profile->id == 7) {
    insp_w = 300;
  }
  shell_layout_adaptive(width, height, insp_w, &layout);

  fill_rect(rgb, width, height, (ShellRect){0, 0, width, height}, k_bg_primary);
  paint_panel_shadow(rgb, width, height, layout.dock, 4);
  paint_panel_shadow(rgb, width, height, layout.inspector, 4);
  paint_panel_shadow(rgb, width, height, layout.timeline, 3);
  fill_gradient_v(rgb, width, height, layout.topbar, k_bg_primary, k_bg_elevated);
  fill_round_rect(rgb, width, height, layout.agent_strip, k_bg_elevated, 6);
  if (profile != NULL) {
    unsigned char accent[3] = {profile->chip_r, profile->chip_g, profile->chip_b};
    paint_topbar_accent(rgb, width, height, layout.topbar, accent);
  }

  stroke_vline(rgb, width, height, layout.dock.x + layout.dock.w, layout.topbar.y,
               layout.topbar.y + layout.topbar.h - 1, k_border);
  stroke_vline(rgb, width, height, layout.inspector.x, layout.inspector.y,
               layout.inspector.y + layout.inspector.h - 1, k_border);
  stroke_hline(rgb, width, height, layout.timeline.x, layout.timeline.x + layout.timeline.w - 1,
               layout.timeline.y, k_border);

  fill_gradient_v(rgb, width, height, layout.dock, k_bg_primary, k_bg_elevated);
  for (int slot = 0; slot < 5; slot++) {
    ShellRect slot_r = dock_active_slot_rect(layout.dock, slot);
    if (slot == 0) {
      fill_round_rect(rgb, width, height, slot_r, k_hover_tint, 4);
      fill_round_rect(rgb, width, height, slot_r, k_accent_cyan, 4);
      stroke_round_rect(rgb, width, height, slot_r, k_focus_ring, 2, 4);
    } else {
      fill_round_rect(rgb, width, height, slot_r, k_hover_tint, 4);
      stroke_round_rect(rgb, width, height, slot_r, k_border, 1, 4);
    }
    ShellRect icon = {slot_r.x + 10, slot_r.y + 10, slot_r.w - 20, slot_r.h - 20};
    unsigned char icon_c[3] = {k_text_muted[0], k_text_muted[1], (unsigned char)(k_text_muted[2] + slot * 9)};
    paint_glyph_bar(rgb, width, height, icon, icon_c);
  }

  ShellRect strip = outliner_strip(layout.dock);
  for (int row = 0; row < 3; row++) {
    ShellRect row_r = outliner_row(strip, row);
    if (row == 0) {
      fill_round_rect(rgb, width, height, row_r, k_hover_tint, 4);
      fill_round_rect(rgb, width, height, row_r, k_accent_mint, 4);
      stroke_round_rect(rgb, width, height, row_r, k_focus_ring, 1, 4);
    } else {
      fill_round_rect(rgb, width, height, row_r, k_bg_elevated, 4);
      stroke_round_rect(rgb, width, height, row_r, k_border, 1, 4);
    }
    ShellRect label = {row_r.x + 6, row_r.y + 4, row_r.w - 12, row_r.h - 8};
    paint_glyph_bar(rgb, width, height, label, row == 0 ? k_text_primary : k_text_muted);
  }

  paint_viewport_profile(rgb, width, height, layout.viewport, profile);

  if (has_selection) {
    paint_inspector_selected(rgb, width, height, layout.inspector);
  } else {
    paint_inspector_empty(rgb, width, height, layout.inspector);
  }

  ShellRect track = timeline_track(layout.timeline);
  fill_gradient_v(rgb, width, height, track, k_bg_primary, k_bg_elevated);
  stroke_round_rect(rgb, width, height, track, k_border, 1, 6);
  ShellRect play = timeline_playhead(track, playhead_pct);
  fill_round_rect(rgb, width, height, play, k_accent_amber, 2);

  ShellRect play_btn = {layout.timeline.x + 8, layout.timeline.y + (layout.timeline.h - 20) / 2, 20, 20};
  stroke_round_rect(rgb, width, height, play_btn, k_accent_cyan, 1, 4);

  ShellRect agent_status = {layout.agent_strip.x + 12, layout.agent_strip.y + 8,
                            layout.agent_strip.w / 3, layout.agent_strip.h - 16};
  fill_round_rect(rgb, width, height, agent_status, k_agent_idle, 4);
  paint_glyph_bar(rgb, width, height, (ShellRect){agent_status.x + 8, agent_status.y + 6, agent_status.w - 16, 10},
                  k_text_muted);
  ShellRect hint = {layout.agent_strip.x + layout.agent_strip.w - 140, layout.agent_strip.y + 8, 128, 16};
  paint_glyph_bar(rgb, width, height, hint, k_text_dim);

  if (profile != NULL) {
    ShellRect chip = profile_chip(layout.topbar, profile->tag_h);
    unsigned char chip_c[] = {profile->chip_r, profile->chip_g, profile->chip_b};
    fill_round_rect(rgb, width, height, chip, chip_c, 4);
    stroke_round_rect(rgb, width, height, chip, k_border, 1, 4);
  }
}
