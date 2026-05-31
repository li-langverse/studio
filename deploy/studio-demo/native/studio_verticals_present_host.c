/* Per-vertical native frame — paint-blit shell chrome (layout/paint contracts from li-ui + li-studio).
 * capture_mode paint_blit: dock/timeline/inspector/viewport regions (not cpu_chip_only stub).
 * Set STUDIO_VERTICALS_CAPTURE_MODE=cpu_chip_only for legacy chip+grid only. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "studio_shell_paint_fb.h"

static void draw_legacy_chip_only(unsigned char* rgb, int w, int h, const ShellProfileVisual* pv) {
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      unsigned char* p = rgb + (y * w + x) * 3;
      p[0] = 13;
      p[1] = 17;
      p[2] = 23;
    }
  }
  for (int x = 0; x < w; x += 64) {
    for (int y = 0; y < h; y++) {
      unsigned char* p = rgb + (y * w + x) * 3;
      p[0] = 48;
      p[1] = 54;
      p[2] = 61;
    }
  }
  for (int y = 0; y < h; y += 64) {
    for (int x = 0; x < w; x++) {
      unsigned char* p = rgb + (y * w + x) * 3;
      p[0] = 48;
      p[1] = 54;
      p[2] = 61;
    }
  }
  int chip_w = 88;
  int chip_x = w - chip_w - 12;
  for (int yy = 12; yy < 12 + pv->tag_h && yy < h; yy++) {
    for (int xx = chip_x; xx < chip_x + chip_w && xx < w; xx++) {
      unsigned char* p = rgb + (yy * w + xx) * 3;
      p[0] = pv->chip_r;
      p[1] = pv->chip_g;
      p[2] = pv->chip_b;
    }
  }
}

static int save_ppm(const unsigned char* rgb, int w, int h, const char* path) {
  FILE* f = fopen(path, "wb");
  if (!f) {
    return -1;
  }
  fprintf(f, "P6\n%d %d\n255\n", w, h);
  fwrite(rgb, 1, (size_t)w * (size_t)h * 3, f);
  fclose(f);
  return 0;
}

static int capture_mode_paint_blit(const char* env_mode, int profile_id) {
  (void)profile_id;
  if (env_mode != NULL && strcmp(env_mode, "cpu_chip_only") == 0) {
    return 0;
  }
  return 1;
}

static int profile_from_env_slug(const char** slug_out) {
  const char* env = getenv("STUDIO_DEMO_PROFILE");
  if (env == NULL || env[0] == '\0') {
    return 0;
  }
  for (int id = 1; id <= 7; id++) {
    const ShellProfileVisual* p = shell_profile_find(id);
    if (p != NULL && strcmp(p->slug, env) == 0) {
      *slug_out = p->slug;
      return p->id;
    }
  }
  return 0;
}

int main(int argc, char** argv) {
  int width = 1920;
  int height = 1080;
  int profile_id = 1;
  const char* out_dir = ".";
  const char* slug = "game";
  const char* env_mode = getenv("STUDIO_VERTICALS_CAPTURE_MODE");
  const int env_pid = profile_from_env_slug(&slug);
  if (env_pid > 0) {
    profile_id = env_pid;
  }
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--width") == 0 && i + 1 < argc) {
      width = atoi(argv[++i]);
    } else if (strcmp(argv[i], "--height") == 0 && i + 1 < argc) {
      height = atoi(argv[++i]);
    } else if (strcmp(argv[i], "--profile-id") == 0 && i + 1 < argc) {
      profile_id = atoi(argv[++i]);
    } else if (strcmp(argv[i], "--slug") == 0 && i + 1 < argc) {
      slug = argv[++i];
    } else if (strcmp(argv[i], "--out") == 0 && i + 1 < argc) {
      out_dir = argv[++i];
    }
  }
  const ShellProfileVisual* pv = shell_profile_find(profile_id);
  if (!pv) {
    fprintf(stderr, "unknown profile_id %d\n", profile_id);
    return 1;
  }
  slug = pv->slug;
  size_t n = (size_t)width * (size_t)height * 3;
  unsigned char* rgb = (unsigned char*)calloc(n, 1);
  if (!rgb) {
    return 2;
  }
  const int paint_blit = capture_mode_paint_blit(env_mode, profile_id);
  if (paint_blit) {
    /* studio_vertical_demo_compose(game): palette path has_selection=1, playhead ~0.35 */
    shell_paint_frame(rgb, width, height, pv, 1, 0.35f);
  } else {
    draw_legacy_chip_only(rgb, width, height, pv);
  }
  char path[512];
  snprintf(path, sizeof(path), "%s/frame-000.ppm", out_dir);
  int ok = save_ppm(rgb, width, height, path);
  free(rgb);
  const char* capture_mode = paint_blit ? "paint_blit" : "cpu_chip_only";
  const char* pixel_source = paint_blit ? "paint_blit" : "cpu_chip_only";
  const char* backend = paint_blit ? "paint_blit_shell" : "cpu_framebuffer";
  printf(
      "{\"native_pixels\":%s,\"profile_id\":%d,\"slug\":\"%s\",\"slug_expected\":\"%s\","
      "\"ppm\":\"%s\",\"width\":%d,\"height\":%d,\"backend\":\"%s\","
      "\"capture_mode\":\"%s\",\"pixel_source\":\"%s\"}\n",
      ok == 0 ? "1" : "0", profile_id, slug, pv->slug, path, width, height, backend, capture_mode,
      pixel_source);
  return ok == 0 ? 0 : 5;
}
