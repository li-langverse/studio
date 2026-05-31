/* Li World Studio — Cloth Simulation
 * 2D cloth grid with Verlet integration, spring constraints, and wind.
 * Build: clang-22 -O2 demos/cloth_demo.c -o demos/cloth_demo -lSDL2 -lm -I/usr/include/SDL2
 * Run:   DISPLAY=:99 ./demos/cloth_demo */
#include <SDL.h>
#include <math.h>
#include <string.h>

enum {
  WIN_W       = 1200,
  WIN_H       = 900,
  COLS        = 20,
  ROWS        = 15,
  N_PARTICLES = COLS * ROWS,
  CONSTRAINT_ITERS = 6,
  FPS_CAP     = 60,
  PARTICLE_R  = 3,
};

#define DT          (1.0 / 60.0)
#define GRAVITY     500.0
#define REST_H      28.0
#define REST_V      28.0
#define DAMPING     0.998
#define WIND_STRENGTH 60.0
#define WIND_FREQ   0.7

#define GRID_OFFSET_X 180.0
#define GRID_OFFSET_Y 80.0

typedef struct {
  double x, y;
  double ox, oy;
  int pinned;
} Particle;

typedef struct {
  int a, b;
  double rest_len;
} Spring;

static Particle particles[N_PARTICLES];
static Spring springs[COLS * ROWS * 2];
static int n_springs;

static int idx(int col, int row) { return row * COLS + col; }

static void init_cloth(void) {
  for (int r = 0; r < ROWS; r++) {
    for (int c = 0; c < COLS; c++) {
      int i = idx(c, r);
      double x = GRID_OFFSET_X + c * REST_H;
      double y = GRID_OFFSET_Y + r * REST_V;
      particles[i].x = x;
      particles[i].y = y;
      particles[i].ox = x;
      particles[i].oy = y;
      particles[i].pinned = (r == 0);
    }
  }

  n_springs = 0;
  for (int r = 0; r < ROWS; r++) {
    for (int c = 0; c < COLS; c++) {
      if (c < COLS - 1) {
        int a = idx(c, r), b = idx(c + 1, r);
        double dx = particles[b].x - particles[a].x;
        double dy = particles[b].y - particles[a].y;
        springs[n_springs].a = a;
        springs[n_springs].b = b;
        springs[n_springs].rest_len = sqrt(dx * dx + dy * dy);
        n_springs++;
      }
      if (r < ROWS - 1) {
        int a = idx(c, r), b = idx(c, r + 1);
        double dx = particles[b].x - particles[a].x;
        double dy = particles[b].y - particles[a].y;
        springs[n_springs].a = a;
        springs[n_springs].b = b;
        springs[n_springs].rest_len = sqrt(dx * dx + dy * dy);
        n_springs++;
      }
    }
  }
}

static void simulate(double t) {
  double wind_x = WIND_STRENGTH * sin(WIND_FREQ * t * 2.0 * M_PI);
  double wind_y = WIND_STRENGTH * 0.3 * cos(WIND_FREQ * t * 1.3 * 2.0 * M_PI);

  for (int i = 0; i < N_PARTICLES; i++) {
    if (particles[i].pinned) continue;
    double vx = (particles[i].x - particles[i].ox) * DAMPING;
    double vy = (particles[i].y - particles[i].oy) * DAMPING;
    particles[i].ox = particles[i].x;
    particles[i].oy = particles[i].y;
    particles[i].x += vx + (wind_x) * DT * DT;
    particles[i].y += vy + (GRAVITY + wind_y) * DT * DT;
  }

  for (int iter = 0; iter < CONSTRAINT_ITERS; iter++) {
    for (int s = 0; s < n_springs; s++) {
      Particle* pa = &particles[springs[s].a];
      Particle* pb = &particles[springs[s].b];
      double dx = pb->x - pa->x;
      double dy = pb->y - pa->y;
      double len = sqrt(dx * dx + dy * dy);
      if (len < 1e-12) continue;
      double diff = (len - springs[s].rest_len) / len;
      double offx = dx * 0.5 * diff;
      double offy = dy * 0.5 * diff;
      if (!pa->pinned) { pa->x += offx; pa->y += offy; }
      if (!pb->pinned) { pb->x -= offx; pb->y -= offy; }
    }
  }
}

static Uint8 clamp_u8(int v) {
  if (v < 0) return 0;
  if (v > 255) return 255;
  return (Uint8)v;
}

static void spring_color(double stretch, Uint8* r, Uint8* g, Uint8* b) {
  double t = stretch;
  if (t < 0.0) t = 0.0;
  if (t > 1.0) t = 1.0;
  *r = clamp_u8((int)(0x33 + t * (0xff - 0x33)));
  *g = clamp_u8((int)(0xff - t * (0xff - 0x66)));
  *b = clamp_u8((int)(0xff - t * (0xff - 0x33)));
}

int main(int argc, char** argv) {
  (void)argc; (void)argv;

  if (SDL_Init(SDL_INIT_VIDEO) != 0) {
    SDL_Log("SDL_Init: %s", SDL_GetError());
    return 1;
  }

  SDL_Window* win = SDL_CreateWindow(
      "Li World Studio \xe2\x80\x94 Cloth Simulation",
      SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
      WIN_W, WIN_H, SDL_WINDOW_SHOWN);
  if (!win) {
    SDL_Log("SDL_CreateWindow: %s", SDL_GetError());
    SDL_Quit();
    return 1;
  }

  SDL_Renderer* ren = SDL_CreateRenderer(win, -1,
      SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
  if (!ren) ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_SOFTWARE);
  if (!ren) {
    SDL_Log("SDL_CreateRenderer: %s", SDL_GetError());
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 1;
  }
  SDL_SetRenderDrawBlendMode(ren, SDL_BLENDMODE_BLEND);

  init_cloth();

  int running = 1;
  double sim_time = 0.0;
  Uint32 frame_start;

  while (running) {
    frame_start = SDL_GetTicks();

    SDL_Event ev;
    while (SDL_PollEvent(&ev)) {
      if (ev.type == SDL_QUIT) running = 0;
      if (ev.type == SDL_KEYDOWN && ev.key.keysym.sym == SDLK_ESCAPE) running = 0;
    }

    simulate(sim_time);
    sim_time += DT;

    SDL_SetRenderDrawColor(ren, 0x0a, 0x0a, 0x1a, 255);
    SDL_RenderClear(ren);

    for (int s = 0; s < n_springs; s++) {
      Particle* pa = &particles[springs[s].a];
      Particle* pb = &particles[springs[s].b];
      double dx = pb->x - pa->x;
      double dy = pb->y - pa->y;
      double len = sqrt(dx * dx + dy * dy);
      double stretch = (len - springs[s].rest_len) / springs[s].rest_len;
      stretch = stretch * 3.0;

      Uint8 cr, cg, cb;
      spring_color(stretch, &cr, &cg, &cb);
      SDL_SetRenderDrawColor(ren, cr, cg, cb, 220);
      SDL_RenderDrawLine(ren, (int)pa->x, (int)pa->y, (int)pb->x, (int)pb->y);
    }

    for (int i = 0; i < N_PARTICLES; i++) {
      int px = (int)particles[i].x;
      int py = (int)particles[i].y;
      if (particles[i].pinned) {
        SDL_SetRenderDrawColor(ren, 0xff, 0xff, 0xff, 255);
      } else {
        SDL_SetRenderDrawColor(ren, 0x88, 0xee, 0xff, 255);
      }
      SDL_Rect dot = { px - PARTICLE_R, py - PARTICLE_R,
                       PARTICLE_R * 2 + 1, PARTICLE_R * 2 + 1 };
      SDL_RenderFillRect(ren, &dot);
    }

    SDL_RenderPresent(ren);

    Uint32 elapsed = SDL_GetTicks() - frame_start;
    Uint32 target = 1000 / FPS_CAP;
    if (elapsed < target) SDL_Delay(target - elapsed);
  }

  SDL_DestroyRenderer(ren);
  SDL_DestroyWindow(win);
  SDL_Quit();
  return 0;
}
