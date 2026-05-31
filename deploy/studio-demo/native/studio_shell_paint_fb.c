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
    stroke_vline(rgb, w, h, x, vp.y, vp.y + vp.h - 1, k_border);
  }
  for (int y = vp.y; y < vp.y + vp.h; y += 64) {
    stroke_hline(rgb, w, h, vp.x, vp.x + vp.w - 1, y, k_border);
  }
  int pad = 24;
  ShellRect frame = {vp.x + pad, vp.y + pad, vp.w - pad * 2, vp.h - pad * 2};
  if (frame.w > 0 && frame.h > 0) {
    stroke_rect(rgb, w, h, frame, k_border, 1);
    ShellRect title = {frame.x + 40, frame.y + frame.h / 3, frame.w / 2, 12};
    fill_rect(rgb, w, h, title, k_border);
    ShellRect cta = {frame.x + frame.w / 4, frame.y + frame.h / 2, frame.w / 2, 28};
    stroke_rect(rgb, w, h, cta, k_border, 1);
  }
}

static void paint_inspector_selected(unsigned char* rgb, int w, int h, ShellRect insp) {
  stroke_rect(rgb, w, h, insp, k_accent_violet, 2);
  ShellRect header = {insp.x, insp.y, insp.w, INSPECTOR_HEADER_H};
  stroke_rect(rgb, w, h, header, k_accent_violet, 1);
  ShellRect field = {insp.x + 12, insp.y + INSPECTOR_HEADER_H + 12, insp.w - 24, 20};
  fill_rect(rgb, w, h, field, k_bg_elevated);
}

static void paint_inspector_empty(unsigned char* rgb, int w, int h, ShellRect insp) {
  stroke_rect(rgb, w, h, insp, k_border, 1);
  ShellRect header = {insp.x, insp.y, insp.w, INSPECTOR_HEADER_H};
  stroke_rect(rgb, w, h, header, k_border, 1);
  ShellRect line1 = {insp.x + 12, insp.y + INSPECTOR_HEADER_H + 16, insp.w - 24, 10};
  ShellRect line2 = {insp.x + 12, line1.y + 18, insp.w - 24, 10};
  fill_rect(rgb, w, h, line1, k_border);
  fill_rect(rgb, w, h, line2, k_border);
  ShellRect box = {insp.x + 12, line2.y + 20, insp.w - 24, 48};
  stroke_rect(rgb, w, h, box, k_border, 1);
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
  fill_rect(rgb, width, height, layout.topbar, k_bg_elevated);
  fill_rect(rgb, width, height, layout.agent_strip, k_bg_elevated);

  stroke_vline(rgb, width, height, layout.dock.x + layout.dock.w, layout.topbar.y,
               layout.topbar.y + layout.topbar.h - 1, k_border);
  stroke_vline(rgb, width, height, layout.inspector.x, layout.inspector.y,
               layout.inspector.y + layout.inspector.h - 1, k_border);
  stroke_hline(rgb, width, height, layout.timeline.x, layout.timeline.x + layout.timeline.w - 1,
               layout.timeline.y, k_border);

  for (int slot = 0; slot < 5; slot++) {
    ShellRect slot_r = dock_active_slot_rect(layout.dock, slot);
    const unsigned char* c = (slot == 0) ? k_accent_cyan : k_border;
    stroke_rect(rgb, width, height, slot_r, c, slot == 0 ? 2 : 1);
  }

  ShellRect strip = outliner_strip(layout.dock);
  for (int row = 0; row < 3; row++) {
    ShellRect row_r = outliner_row(strip, row);
    const unsigned char* c = (row == 0) ? k_accent_mint : k_border;
    stroke_rect(rgb, width, height, row_r, c, 1);
  }

  paint_viewport_grid(rgb, width, height, layout.viewport);

  if (has_selection) {
    paint_inspector_selected(rgb, width, height, layout.inspector);
  } else {
    paint_inspector_empty(rgb, width, height, layout.inspector);
  }

  ShellRect track = timeline_track(layout.timeline);
  stroke_rect(rgb, width, height, track, k_border, 1);
  ShellRect play = timeline_playhead(track, playhead_pct);
  fill_rect(rgb, width, height, play, k_accent_amber);

  ShellRect play_btn = {layout.timeline.x + 8, layout.timeline.y + (layout.timeline.h - 20) / 2, 20, 20};
  stroke_rect(rgb, width, height, play_btn, k_accent_cyan, 1);

  ShellRect agent_status = {layout.agent_strip.x + 12, layout.agent_strip.y + 8,
                            layout.agent_strip.w / 3, layout.agent_strip.h - 16};
  fill_rect(rgb, width, height, agent_status, k_agent_idle);

  if (profile != NULL) {
    ShellRect chip = profile_chip(layout.topbar, profile->tag_h);
    unsigned char chip_c[] = {profile->chip_r, profile->chip_g, profile->chip_b};
    fill_rect(rgb, width, height, chip, chip_c);
    stroke_rect(rgb, width, height, chip, chip_c, 1);
  }
}
