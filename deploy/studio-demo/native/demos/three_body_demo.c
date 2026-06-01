/* Li World Studio — Three-Body Problem
 * Real-time gravitational N-body with orbital trails and glow.
 * Build: clang-22 -O2 demos/three_body_demo.c -o demos/three_body_demo -lSDL2 -lm -I/usr/include/SDL2
 * Run:   DISPLAY=:99 ./demos/three_body_demo */
#include <SDL.h>
#include <math.h>
#include <string.h>

enum {
  WIN_W          = 1200,
  WIN_H          = 900,
  N_BODIES       = 3,
  TRAIL_LEN      = 2000,
  STEPS_PER_FRAME = 80,
  GLOW_RADIUS    = 18,
  BODY_RADIUS    = 5,
  FPS_CAP        = 60,
};

#define DT       0.001
#define G_CONST  1.0
#define MASS     1.0
#define SOFT2    1e-4
#define SCALE    120.0

typedef struct {
  double px[N_BODIES], py[N_BODIES];
  double vx[N_BODIES], vy[N_BODIES];
} State;

typedef struct {
  double x[TRAIL_LEN], y[TRAIL_LEN];
  int head, count;
} Trail;

static const Uint8 body_colors[N_BODIES][3] = {
  {0xff, 0x33, 0x66},
  {0x33, 0xff, 0x99},
  {0x33, 0x99, 0xff},
};

static void init_state(State* s) {
  const double r = 1.0;
  s->px[0] =  0.0;               s->py[0] =  r;
  s->px[1] = -0.8660254037844386 * r; s->py[1] = -0.5 * r;
  s->px[2] =  0.8660254037844386 * r; s->py[2] = -0.5 * r;

  double angle = 0.4;
  double speed = 0.45;
  for (int i = 0; i < N_BODIES; i++) {
    double cx = -s->py[i], cy = s->px[i];
    double norm = sqrt(cx * cx + cy * cy);
    if (norm > 1e-12) { cx /= norm; cy /= norm; }
    s->vx[i] = speed * cx;
    s->vy[i] = speed * cy;
  }
  s->vx[0] += 0.02;
  s->vy[1] -= 0.015;
  (void)angle;
}

static void compute_forces(const State* s, double fx[N_BODIES], double fy[N_BODIES]) {
  memset(fx, 0, sizeof(double) * N_BODIES);
  memset(fy, 0, sizeof(double) * N_BODIES);
  for (int i = 0; i < N_BODIES; i++) {
    for (int j = i + 1; j < N_BODIES; j++) {
      double dx = s->px[j] - s->px[i];
      double dy = s->py[j] - s->py[i];
      double r2 = dx * dx + dy * dy + SOFT2;
      double inv_r = 1.0 / sqrt(r2);
      double inv_r3 = inv_r * inv_r * inv_r;
      double scale = G_CONST * MASS * MASS * inv_r3;
      double ffx = scale * dx;
      double ffy = scale * dy;
      fx[i] += ffx; fy[i] += ffy;
      fx[j] -= ffx; fy[j] -= ffy;
    }
  }
}

static void step_leapfrog(State* s) {
  double fx[N_BODIES], fy[N_BODIES];
  compute_forces(s, fx, fy);
  for (int i = 0; i < N_BODIES; i++) {
    s->vx[i] += 0.5 * DT * fx[i] / MASS;
    s->vy[i] += 0.5 * DT * fy[i] / MASS;
  }
  for (int i = 0; i < N_BODIES; i++) {
    s->px[i] += DT * s->vx[i];
    s->py[i] += DT * s->vy[i];
  }
  compute_forces(s, fx, fy);
  for (int i = 0; i < N_BODIES; i++) {
    s->vx[i] += 0.5 * DT * fx[i] / MASS;
    s->vy[i] += 0.5 * DT * fy[i] / MASS;
  }
}

static void trail_push(Trail* t, double x, double y) {
  t->x[t->head] = x;
  t->y[t->head] = y;
  t->head = (t->head + 1) % TRAIL_LEN;
  if (t->count < TRAIL_LEN) t->count++;
}

static void world_to_screen(double wx, double wy, double cx, double cy,
                             int* sx, int* sy) {
  *sx = (int)(WIN_W / 2.0 + (wx - cx) * SCALE);
  *sy = (int)(WIN_H / 2.0 - (wy - cy) * SCALE);
}

static void draw_filled_circle(SDL_Renderer* ren, int cx, int cy, int r) {
  for (int dy = -r; dy <= r; dy++) {
    int dx = (int)sqrt((double)(r * r - dy * dy));
    SDL_RenderDrawLine(ren, cx - dx, cy + dy, cx + dx, cy + dy);
  }
}

static void draw_glow(SDL_Renderer* ren, int cx, int cy, int radius,
                       Uint8 cr, Uint8 cg, Uint8 cb) {
  for (int ring = radius; ring >= 1; ring--) {
    double t = (double)ring / (double)radius;
    Uint8 alpha = (Uint8)(255.0 * (1.0 - t) * (1.0 - t));
    SDL_SetRenderDrawColor(ren, cr, cg, cb, alpha);
    for (int dy = -ring; dy <= ring; dy++) {
      int dx = (int)sqrt((double)(ring * ring - dy * dy));
      SDL_RenderDrawLine(ren, cx - dx, cy + dy, cx + dx, cy + dy);
    }
  }
}

int main(int argc, char** argv) {
  (void)argc; (void)argv;

  if (SDL_Init(SDL_INIT_VIDEO) != 0) {
    SDL_Log("SDL_Init: %s", SDL_GetError());
    return 1;
  }

  SDL_Window* win = SDL_CreateWindow(
      "Li World Studio \xe2\x80\x94 Three-Body Problem",
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

  State state;
  init_state(&state);

  Trail trails[N_BODIES];
  memset(trails, 0, sizeof(trails));

  int running = 1;
  Uint32 frame_start;

  while (running) {
    frame_start = SDL_GetTicks();

    SDL_Event ev;
    while (SDL_PollEvent(&ev)) {
      if (ev.type == SDL_QUIT) running = 0;
      if (ev.type == SDL_KEYDOWN && ev.key.keysym.sym == SDLK_ESCAPE) running = 0;
    }

    for (int s = 0; s < STEPS_PER_FRAME; s++) {
      step_leapfrog(&state);
    }

    for (int i = 0; i < N_BODIES; i++) {
      trail_push(&trails[i], state.px[i], state.py[i]);
    }

    double cx = 0, cy = 0;
    for (int i = 0; i < N_BODIES; i++) {
      cx += state.px[i]; cy += state.py[i];
    }
    cx /= N_BODIES; cy /= N_BODIES;

    SDL_SetRenderDrawColor(ren, 0x0a, 0x0a, 0x1a, 255);
    SDL_RenderClear(ren);

    for (int b = 0; b < N_BODIES; b++) {
      Trail* tr = &trails[b];
      Uint8 cr = body_colors[b][0];
      Uint8 cg = body_colors[b][1];
      Uint8 cb = body_colors[b][2];

      for (int k = 1; k < tr->count; k++) {
        int i0 = (tr->head - tr->count + k - 1 + TRAIL_LEN) % TRAIL_LEN;
        int i1 = (tr->head - tr->count + k     + TRAIL_LEN) % TRAIL_LEN;

        double fade = (double)k / (double)tr->count;
        Uint8 alpha = (Uint8)(fade * fade * 200.0);

        int sx0, sy0, sx1, sy1;
        world_to_screen(tr->x[i0], tr->y[i0], cx, cy, &sx0, &sy0);
        world_to_screen(tr->x[i1], tr->y[i1], cx, cy, &sx1, &sy1);

        SDL_SetRenderDrawColor(ren, cr, cg, cb, alpha);
        SDL_RenderDrawLine(ren, sx0, sy0, sx1, sy1);
      }
    }

    for (int b = 0; b < N_BODIES; b++) {
      int sx, sy;
      world_to_screen(state.px[b], state.py[b], cx, cy, &sx, &sy);
      draw_glow(ren, sx, sy, GLOW_RADIUS,
                body_colors[b][0], body_colors[b][1], body_colors[b][2]);
      SDL_SetRenderDrawColor(ren, body_colors[b][0], body_colors[b][1],
                             body_colors[b][2], 255);
      draw_filled_circle(ren, sx, sy, BODY_RADIUS);
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
