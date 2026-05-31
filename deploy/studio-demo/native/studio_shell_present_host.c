/* STUDIO_SHELL_HOST_IO_ONLY — SDL window/input/surface I/O; no C paint mirror.
 * Product pixels: Li studio_shell_present_raster_and_blit → --rgb-ppm blit path.
 * Build: build-studio-shell-present-host.ps1 (no studio_shell_paint_fb.c)
 * Run:  LIG_HOST_PRESENT=1 ./studio_shell_present_host --width 1280 --height 720
 *       ./studio_shell_present_host --width 640 --height 360 --rgb-ppm frame.ppm --persist
 */
#include <SDL.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  int pointer_down;
  float pointer_x;
  float pointer_y;
  int key_escape;
  int key_cmd_k;
  int key_digit;
} HostInputState;

static void host_input_reset(HostInputState* s) {
  memset(s, 0, sizeof(*s));
}

static void host_input_map_keys(const Uint8* keys, HostInputState* s) {
  if (keys[SDL_SCANCODE_ESCAPE]) {
    s->key_escape = 1;
  }
  SDL_Keymod mod = SDL_GetModState();
  if ((mod & KMOD_GUI) || (mod & KMOD_CTRL)) {
    if (keys[SDL_SCANCODE_K]) {
      s->key_cmd_k = 1;
    }
  }
  static const SDL_Scancode digit_sc[] = {
      SDL_SCANCODE_1, SDL_SCANCODE_2, SDL_SCANCODE_3,
      SDL_SCANCODE_4, SDL_SCANCODE_5,
  };
  for (int d = 0; d < 5; d++) {
    if (keys[digit_sc[d]]) {
      s->key_digit = d + 1;
      break;
    }
  }
}

static void host_input_export_env(const HostInputState* s) {
  char buf[64];
  snprintf(buf, sizeof(buf), "%d", s->pointer_down);
  setenv("STUDIO_SHELL_POINTER_DOWN", buf, 1);
  snprintf(buf, sizeof(buf), "%.1f", s->pointer_x);
  setenv("STUDIO_SHELL_POINTER_X", buf, 1);
  snprintf(buf, sizeof(buf), "%.1f", s->pointer_y);
  setenv("STUDIO_SHELL_POINTER_Y", buf, 1);
  setenv("STUDIO_SHELL_KEY_ESCAPE", s->key_escape ? "1" : "0", 1);
  setenv("STUDIO_SHELL_KEY_CMD_K", s->key_cmd_k ? "1" : "0", 1);
  if (s->key_digit >= 1 && s->key_digit <= 5) {
    snprintf(buf, sizeof(buf), "%d", s->key_digit);
    setenv("STUDIO_SHELL_KEY_DIGIT", buf, 1);
  } else {
    unsetenv("STUDIO_SHELL_KEY_DIGIT");
  }
}

static void host_input_poll_mouse(HostInputState* s) {
  int mx = 0, my = 0;
  Uint32 buttons = SDL_GetMouseState(&mx, &my);
  s->pointer_x = (float)mx;
  s->pointer_y = (float)my;
  s->pointer_down = (buttons & SDL_BUTTON(SDL_BUTTON_LEFT)) ? 1 : 0;
}

static int load_ppm_rgb(const char* path, unsigned char** rgb_out, int* w_out, int* h_out) {
  FILE* f = fopen(path, "rb");
  if (!f) {
    return -1;
  }
  char magic[3] = {0};
  if (fread(magic, 1, 2, f) != 2 || magic[0] != 'P' || magic[1] != '6') {
    fclose(f);
    return -1;
  }
  int w = 0, h = 0, maxv = 0;
  if (fscanf(f, " %d %d %d", &w, &h, &maxv) != 3 || w <= 0 || h <= 0) {
    fclose(f);
    return -1;
  }
  fgetc(f);
  size_t n = (size_t)w * (size_t)h * 3;
  unsigned char* rgb = (unsigned char*)malloc(n);
  if (!rgb) {
    fclose(f);
    return -1;
  }
  if (fread(rgb, 1, n, f) != n) {
    free(rgb);
    fclose(f);
    return -1;
  }
  fclose(f);
  *rgb_out = rgb;
  *w_out = w;
  *h_out = h;
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

static unsigned char* solid_rgb(int w, int h) {
  size_t n = (size_t)w * (size_t)h * 3;
  unsigned char* rgb = (unsigned char*)calloc(n, 1);
  if (!rgb) {
    return NULL;
  }
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      unsigned char* p = rgb + (y * w + x) * 3;
      p[0] = 13;
      p[1] = 17;
      p[2] = 23;
    }
  }
  return rgb;
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

static int present_rgb(SDL_Renderer* ren, const unsigned char* rgb, int w, int h) {
  SDL_Texture* tex = upload_rgb(ren, rgb, w, h);
  if (!tex) {
    return 1;
  }
  SDL_SetRenderDrawColor(ren, 0, 0, 0, 255);
  SDL_RenderClear(ren);
  SDL_RenderCopy(ren, tex, NULL, NULL);
  SDL_RenderPresent(ren);
  SDL_DestroyTexture(tex);
  return 0;
}

static void print_json(int width, int height, int persist, const char* rgb_ppm, int li_pixels) {
  const char* pixel_source = li_pixels ? "li_rgb_ppm" : "surface_io_only";
  const char* backend = li_pixels ? "sdl_li_blit" : "sdl_io_only";
  printf(
      "{\"presented\":1,\"native_pixels\":1,\"backend\":\"%s\","
      "\"capture_mode\":\"%s\",\"pixel_source\":\"%s\","
      "\"host_io_only\":1,\"width\":%d,\"height\":%d,\"persist\":%d,"
      "\"rgb_ppm\":%s,\"chrome\":\"li_studio_raster\"}\n",
      backend, pixel_source, pixel_source, width, height, persist,
      rgb_ppm ? "true" : "false");
  fflush(stdout);
}

int main(int argc, char** argv) {
  int width = 1280;
  int height = 720;
  const char* rgb_ppm = NULL;
  const char* screenshot = NULL;
  int persist = 0;

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--width") == 0 && i + 1 < argc) {
      width = atoi(argv[++i]);
    } else if (strcmp(argv[i], "--height") == 0 && i + 1 < argc) {
      height = atoi(argv[++i]);
    } else if (strcmp(argv[i], "--rgb-ppm") == 0 && i + 1 < argc) {
      rgb_ppm = argv[++i];
    } else if (strcmp(argv[i], "--screenshot") == 0 && i + 1 < argc) {
      screenshot = argv[++i];
    } else if (strcmp(argv[i], "--persist") == 0 || strcmp(argv[i], "--interactive") == 0) {
      persist = 1;
    }
  }

  if (rgb_ppm == NULL) {
    rgb_ppm = getenv("STUDIO_SHELL_RGB_PPM");
  }
  if (getenv("STUDIO_SHELL_PERSIST") != NULL && getenv("STUDIO_SHELL_PERSIST")[0] == '1') {
    persist = 1;
  }

  if (SDL_Init(SDL_INIT_VIDEO) != 0) {
    fprintf(stderr, "SDL_Init failed: %s\n", SDL_GetError());
    return 2;
  }

  Uint32 window_flags = SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE;
  if (!persist && screenshot == NULL) {
    window_flags = SDL_WINDOW_HIDDEN;
  }

  SDL_Window* win = SDL_CreateWindow(
      "Li World Studio", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height, window_flags);
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

  unsigned char* rgb = NULL;
  int rgb_w = width;
  int rgb_h = height;
  int li_pixels = 0;
  if (rgb_ppm != NULL && load_ppm_rgb(rgb_ppm, &rgb, &rgb_w, &rgb_h) == 0) {
    li_pixels = 1;
  } else {
    rgb = solid_rgb(width, height);
    if (!rgb) {
      SDL_DestroyRenderer(ren);
      SDL_DestroyWindow(win);
      SDL_Quit();
      return 5;
    }
    rgb_w = width;
    rgb_h = height;
  }

  if (present_rgb(ren, rgb, rgb_w, rgb_h) != 0) {
    free(rgb);
    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 6;
  }

  if (screenshot != NULL) {
    if (save_ppm(rgb, rgb_w, rgb_h, screenshot) != 0) {
      fprintf(stderr, "save_ppm failed: %s\n", screenshot);
    }
  }

  print_json(width, height, persist, rgb_ppm, li_pixels);

  HostInputState input;
  host_input_reset(&input);

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
        }
      }
      const Uint8* keys = SDL_GetKeyboardState(NULL);
      host_input_reset(&input);
      host_input_map_keys(keys, &input);
      host_input_poll_mouse(&input);
      host_input_export_env(&input);

      Uint32 now = SDL_GetTicks();
      if (now - last >= 33) {
        if (rgb_ppm != NULL && load_ppm_rgb(rgb_ppm, &rgb, &rgb_w, &rgb_h) == 0) {
          li_pixels = 1;
          present_rgb(ren, rgb, rgb_w, rgb_h);
        }
        last = now;
      }
      SDL_Delay(1);
    }
  }

  free(rgb);
  SDL_DestroyRenderer(ren);
  SDL_DestroyWindow(win);
  SDL_Quit();
  return 0;
}
