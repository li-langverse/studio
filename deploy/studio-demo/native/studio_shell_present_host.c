/* Li World Studio SDL present host — real native window with shell chrome paint blit.
 * Renders layout/paint contracts shared with li-studio studio_paint_shell_chrome (paint_fb).
 * Build: build-studio-shell-present-host.ps1 (or native-sdl-build.sh with paint_fb.c)
 * Run:  ./studio_shell_present_host --width 1280 --height 720 --persist
 *       LIG_HOST_PRESENT=1 li-studio-demo  (one-shot present tick via STUDIO_SHELL_PRESENT_HOST_BIN)
 */
#include <SDL.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "studio_shell_paint_fb.h"

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

static int save_ppm(const unsigned char* rgb, int w, int h, const char* path) {
  FILE* f = fopen(path, "wb");
  if (!f) {
    return -1;
  }
  fprintf(f, "P6\n%d %d\n255\n", w, h);
  if (fwrite(rgb, 1, (size_t)w * (size_t)h * 3, f) != (size_t)w * (size_t)h * 3) {
    fclose(f);
    return -1;
  }
  fclose(f);
  return 0;
}

static SDL_Texture* upload_rgb(SDL_Renderer* ren, const unsigned char* rgb, int w, int h) {
  SDL_Texture* tex = SDL_CreateTexture(ren, SDL_PIXELFORMAT_RGB24, SDL_TEXTUREACCESS_STREAMING, w, h);
  if (!tex) {
    return NULL;
  }
  void* pixels = NULL;
  int pitch = 0;
  if (SDL_LockTexture(tex, NULL, &pixels, &pitch) != 0) {
    SDL_DestroyTexture(tex);
    return NULL;
  }
  for (int y = 0; y < h; y++) {
    memcpy((unsigned char*)pixels + y * pitch, rgb + y * w * 3, (size_t)w * 3);
  }
  SDL_UnlockTexture(tex);
  return tex;
}

static int render_shell_frame(SDL_Renderer* ren, int width, int height, int profile_id, float playhead_pct) {
  const ShellProfileVisual* pv = shell_profile_find(profile_id);
  if (!pv) {
    return 1;
  }
  size_t n = (size_t)width * (size_t)height * 3;
  unsigned char* rgb = (unsigned char*)calloc(n, 1);
  if (!rgb) {
    return 2;
  }
  shell_paint_frame(rgb, width, height, pv, 1, playhead_pct);

  SDL_Texture* tex = upload_rgb(ren, rgb, width, height);
  if (!tex) {
    free(rgb);
    return 3;
  }
  SDL_SetRenderDrawColor(ren, 0, 0, 0, 255);
  SDL_RenderClear(ren);
  SDL_RenderCopy(ren, tex, NULL, NULL);
  SDL_RenderPresent(ren);
  SDL_DestroyTexture(tex);
  free(rgb);
  return 0;
}

static void print_json(int width, int height, int profile_id, const char* slug, int persist) {
  const ShellProfileVisual* pv = shell_profile_find(profile_id);
  const char* profile_slug = slug;
  if (pv != NULL) {
    profile_slug = pv->slug;
  }
  printf(
      "{\"presented\":1,\"native_pixels\":1,\"backend\":\"sdl_paint_blit\","
      "\"capture_mode\":\"paint_blit\",\"pixel_source\":\"paint_blit\","
      "\"width\":%d,\"height\":%d,\"profile_id\":%d,\"slug\":\"%s\","
      "\"persist\":%d,\"chrome\":\"studio_paint_shell_chrome\"}\n",
      width, height, profile_id, profile_slug, persist);
  fflush(stdout);
}

int main(int argc, char** argv) {
  int width = 1280;
  int height = 720;
  int profile_id = 1;
  const char* slug = "game";
  const char* screenshot = NULL;
  int persist = 0;
  float playhead_pct = 0.35f;

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
    } else if (strcmp(argv[i], "--playhead") == 0 && i + 1 < argc) {
      playhead_pct = (float)atof(argv[++i]);
    } else if (strcmp(argv[i], "--screenshot") == 0 && i + 1 < argc) {
      screenshot = argv[++i];
    } else if (strcmp(argv[i], "--persist") == 0 || strcmp(argv[i], "--interactive") == 0) {
      persist = 1;
    }
  }

  if (getenv("STUDIO_SHELL_PERSIST") != NULL && getenv("STUDIO_SHELL_PERSIST")[0] == '1') {
    persist = 1;
  }

  const ShellProfileVisual* pv = shell_profile_find(profile_id);
  if (!pv) {
    fprintf(stderr, "unknown profile_id %d\n", profile_id);
    return 1;
  }
  slug = pv->slug;

  if (SDL_Init(SDL_INIT_VIDEO) != 0) {
    fprintf(stderr, "SDL_Init failed: %s\n", SDL_GetError());
    return 2;
  }

  Uint32 window_flags = SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE;
  if (!persist && screenshot == NULL) {
    window_flags = SDL_WINDOW_HIDDEN;
  }

  char title[128];
  snprintf(title, sizeof(title), "Li World Studio — %s", slug);
  SDL_Window* win = SDL_CreateWindow(title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height, window_flags);
  if (!win) {
    fprintf(stderr, "SDL_CreateWindow failed: %s\n", SDL_GetError());
    SDL_Quit();
    return 3;
  }

  SDL_Renderer* ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED);
  if (!ren) {
    ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_SOFTWARE);
  }
  if (!ren) {
    fprintf(stderr, "SDL_CreateRenderer failed: %s\n", SDL_GetError());
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 4;
  }

  if (render_shell_frame(ren, width, height, profile_id, playhead_pct) != 0) {
    fprintf(stderr, "render_shell_frame failed\n");
    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 5;
  }

  if (screenshot != NULL) {
    size_t n = (size_t)width * (size_t)height * 3;
    unsigned char* rgb = (unsigned char*)calloc(n, 1);
    if (rgb != NULL) {
      shell_paint_frame(rgb, width, height, pv, 1, playhead_pct);
      if (save_ppm(rgb, width, height, screenshot) != 0) {
        fprintf(stderr, "save_ppm failed: %s\n", screenshot);
      }
      free(rgb);
    }
  }

  print_json(width, height, profile_id, slug, persist);

  if (persist) {
    int running = 1;
    Uint32 last = SDL_GetTicks();
    while (running) {
      SDL_Event ev;
      while (SDL_PollEvent(&ev)) {
        if (ev.type == SDL_QUIT) {
          running = 0;
        } else if (ev.type == SDL_KEYDOWN && ev.key.keysym.sym == SDLK_ESCAPE) {
          running = 0;
        } else if (ev.type == SDL_WINDOWEVENT && ev.window.event == SDL_WINDOWEVENT_SIZE_CHANGED) {
          width = ev.window.data1;
          height = ev.window.data2;
          render_shell_frame(ren, width, height, profile_id, playhead_pct);
        }
      }
      Uint32 now = SDL_GetTicks();
      if (now - last >= 33) {
        playhead_pct += 0.01f;
        if (playhead_pct > 1.0f) {
          playhead_pct = 0.0f;
        }
        render_shell_frame(ren, width, height, profile_id, playhead_pct);
        last = now;
      }
      SDL_Delay(1);
    }
  }

  SDL_DestroyRenderer(ren);
  SDL_DestroyWindow(win);
  SDL_Quit();
  return 0;
}
