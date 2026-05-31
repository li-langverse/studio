/* CPU framebuffer paint blit — mirrors layout_studio_shell_adaptive + studio_paint_shell_chrome. */
#ifndef STUDIO_SHELL_PAINT_FB_H
#define STUDIO_SHELL_PAINT_FB_H

#include <stddef.h>

typedef struct {
  int x;
  int y;
  int w;
  int h;
} ShellRect;

typedef struct {
  ShellRect dock;
  ShellRect topbar;
  ShellRect viewport;
  ShellRect inspector;
  ShellRect timeline;
  ShellRect agent_strip;
} ShellLayout;

typedef struct {
  int id;
  const char* slug;
  int tag_h;
  unsigned char chip_r;
  unsigned char chip_g;
  unsigned char chip_b;
} ShellProfileVisual;

/* Layout + paint at (width x height); has_selection matches studio_vertical_demo palette compose. */
void shell_layout_adaptive(int width, int height, int inspector_w, ShellLayout* out);
void shell_paint_frame(unsigned char* rgb, int width, int height, const ShellProfileVisual* profile,
                       int has_selection, float playhead_pct);

const ShellProfileVisual* shell_profile_find(int profile_id);

#endif
