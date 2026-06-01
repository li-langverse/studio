/* Li World Studio — SPH 2D dam-break fluid demo (SDL2, no SDL_ttf).
 *
 * Physics extracted from benchmarks/tier2_physics/sph_dam_break_2d/common/sph_dam_core.c
 * 256 particles, Verlet integration, SPH pairwise repulsion, gravity, boundary clamp.
 *
 * Build:
 *   clang-22 -O2 demos/sph_fluid_demo.c -o demos/sph_fluid_demo -lSDL2 -lm -I/usr/include/SDL2
 * Run:
 *   DISPLAY=:99 ./demos/sph_fluid_demo            (headless with Xvfb)
 *   ./demos/sph_fluid_demo                         (native display)
 *   ./demos/sph_fluid_demo --frames 600 --headless (auto-quit after N frames)
 */
#include <SDL.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ── SPH constants (from sph_dam_core.c) ─────────────────────────── */
#define SPH_N       256
#define SPH_BOX     1.0
#define SPH_H       0.08
#define SPH_MASS    1.0
#define SPH_DT      0.00025
#define SPH_G       9.81
#define SPH_K       500.0

/* ── Visual constants ────────────────────────────────────────────── */
#define WIN_W       1200
#define WIN_H       900
#define SIM_PAD     60
#define SIM_W       (WIN_W - 2 * SIM_PAD)
#define SIM_H       (WIN_H - 2 * SIM_PAD)
#define SUBSTEPS    80
#define BG_R        0x0A
#define BG_G        0x0A
#define BG_B        0x1A

typedef struct {
    double x[2];
    double v[2];
    double a[2];
} Particle;

static Particle g_p[SPH_N];
static int      g_step;

/* ── SPH init: 16×16 column on the left ─────────────────────────── */
static void sph_init(void) {
    int idx = 0;
    const int nx = 16, ny = 16;
    const double dx = 0.04;
    for (int j = 0; j < ny && idx < SPH_N; ++j) {
        for (int i = 0; i < nx && idx < SPH_N; ++i) {
            g_p[idx].x[0] = 0.05 + (double)i * dx;
            g_p[idx].x[1] = 0.05 + (double)j * dx;
            g_p[idx].v[0] = 0.0;
            g_p[idx].v[1] = 0.0;
            g_p[idx].a[0] = 0.0;
            g_p[idx].a[1] = -SPH_G;
            ++idx;
        }
    }
    for (; idx < SPH_N; ++idx)
        memset(&g_p[idx], 0, sizeof(g_p[idx]));
    g_step = 0;
}

/* ── SPH forces: gravity + pairwise repulsion + boundary clamp ─── */
static void sph_forces(void) {
    for (int i = 0; i < SPH_N; ++i) {
        g_p[i].a[0] = 0.0;
        g_p[i].a[1] = -SPH_G;
    }
    const double h2 = SPH_H * SPH_H;
    (void)h2;
    for (int i = 0; i < SPH_N; ++i) {
        for (int j = i + 1; j < SPH_N; ++j) {
            const double rx = g_p[j].x[0] - g_p[i].x[0];
            const double ry = g_p[j].x[1] - g_p[i].x[1];
            const double r2 = rx * rx + ry * ry + 1e-12;
            const double r  = sqrt(r2);
            if (r >= SPH_H) continue;
            const double q  = 1.0 - r / SPH_H;
            const double f  = SPH_K * q * q / r;
            const double fx = f * rx;
            const double fy = f * ry;
            g_p[i].a[0] -= fx;
            g_p[i].a[1] -= fy;
            g_p[j].a[0] += fx;
            g_p[j].a[1] += fy;
        }
    }
    for (int i = 0; i < SPH_N; ++i) {
        if (g_p[i].x[0] < 0.0) { g_p[i].x[0] = 0.0; g_p[i].v[0] = 0.0; }
        if (g_p[i].x[0] > SPH_BOX) { g_p[i].x[0] = SPH_BOX; g_p[i].v[0] = 0.0; }
        if (g_p[i].x[1] < 0.0) { g_p[i].x[1] = 0.0; g_p[i].v[1] = 0.0; }
        if (g_p[i].x[1] > SPH_BOX) { g_p[i].x[1] = SPH_BOX; g_p[i].v[1] = 0.0; }
    }
}

/* ── Velocity Verlet step (same as sph_dam_core.c kernel body) ─── */
static void sph_step(void) {
    sph_forces();
    for (int i = 0; i < SPH_N; ++i) {
        g_p[i].v[0] += 0.5 * SPH_DT * g_p[i].a[0];
        g_p[i].v[1] += 0.5 * SPH_DT * g_p[i].a[1];
        g_p[i].x[0] += SPH_DT * g_p[i].v[0];
        g_p[i].x[1] += SPH_DT * g_p[i].v[1];
    }
    sph_forces();
    for (int i = 0; i < SPH_N; ++i) {
        g_p[i].v[0] += 0.5 * SPH_DT * g_p[i].a[0];
        g_p[i].v[1] += 0.5 * SPH_DT * g_p[i].a[1];
    }
    ++g_step;
}

/* ── Coordinate transforms: sim [0,1] → screen pixels ───────────── */
static int sx(double v) { return SIM_PAD + (int)(v * SIM_W); }
static int sy(double v) { return WIN_H - SIM_PAD - (int)(v * SIM_H); }

/* ── Draw a filled circle (midpoint algorithm, no SDL_gfx) ──────── */
static void fill_circle(SDL_Renderer* ren, int cx, int cy, int r) {
    for (int dy = -r; dy <= r; ++dy) {
        int half = (int)sqrt((double)(r * r - dy * dy));
        SDL_RenderDrawLine(ren, cx - half, cy + dy, cx + half, cy + dy);
    }
}

/* ── Velocity magnitude → color ramp (deep blue → cyan → white) ── */
static void vel_color(double speed, Uint8* r, Uint8* g, Uint8* b) {
    double t = speed / 3.0;
    if (t > 1.0) t = 1.0;
    if (t < 0.3) {
        double s = t / 0.3;
        *r = (Uint8)(10 + 20 * s);
        *g = (Uint8)(30 + 80 * s);
        *b = (Uint8)(120 + 100 * s);
    } else if (t < 0.7) {
        double s = (t - 0.3) / 0.4;
        *r = (Uint8)(30 + 30 * s);
        *g = (Uint8)(110 + 100 * s);
        *b = (Uint8)(220 + 35 * s);
    } else {
        double s = (t - 0.7) / 0.3;
        *r = (Uint8)(60 + 195 * s);
        *g = (Uint8)(210 + 45 * s);
        *b = 255;
    }
}

/* ── Simple digit renderer using SDL rectangles (no SDL_ttf) ────── */
static const Uint8 DIGIT_SEG[10] = {
    0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B
};

static void draw_seg_h(SDL_Renderer* ren, int x, int y, int w) {
    SDL_Rect r = {x + 1, y, w - 2, 2};
    SDL_RenderFillRect(ren, &r);
}
static void draw_seg_v(SDL_Renderer* ren, int x, int y, int h) {
    SDL_Rect r = {x, y + 1, 2, h - 2};
    SDL_RenderFillRect(ren, &r);
}

static void draw_digit(SDL_Renderer* ren, int x, int y, int d, int w, int h) {
    Uint8 s = DIGIT_SEG[d % 10];
    int hh = h / 2;
    if (s & 0x40) draw_seg_h(ren, x, y, w);
    if (s & 0x20) draw_seg_v(ren, x + w - 2, y, hh);
    if (s & 0x10) draw_seg_v(ren, x + w - 2, y + hh, hh);
    if (s & 0x08) draw_seg_h(ren, x, y + h - 2, w);
    if (s & 0x04) draw_seg_v(ren, x, y + hh, hh);
    if (s & 0x02) draw_seg_v(ren, x, y, hh);
    if (s & 0x01) draw_seg_h(ren, x, y + hh - 1, w);
}

static void draw_number(SDL_Renderer* ren, int x, int y, int val) {
    char buf[16];
    snprintf(buf, sizeof(buf), "%d", val);
    int len = (int)strlen(buf);
    for (int i = 0; i < len; ++i)
        draw_digit(ren, x + i * 12, y, buf[i] - '0', 10, 16);
}

static void draw_char_P(SDL_Renderer* ren, int x, int y) {
    draw_seg_v(ren, x, y, 16);
    draw_seg_h(ren, x, y, 10);
    draw_seg_v(ren, x + 8, y, 8);
    draw_seg_h(ren, x, y + 7, 10);
}
static void draw_char_colon(SDL_Renderer* ren, int x, int y) {
    SDL_Rect r1 = {x + 1, y + 3, 2, 2};
    SDL_Rect r2 = {x + 1, y + 11, 2, 2};
    SDL_RenderFillRect(ren, &r1);
    SDL_RenderFillRect(ren, &r2);
}
static void draw_char_T(SDL_Renderer* ren, int x, int y) {
    draw_seg_h(ren, x, y, 10);
    draw_seg_v(ren, x + 4, y, 16);
}
static void draw_char_dot(SDL_Renderer* ren, int x, int y) {
    SDL_Rect r = {x + 1, y + 14, 2, 2};
    SDL_RenderFillRect(ren, &r);
}
static void draw_char_s(SDL_Renderer* ren, int x, int y) {
    draw_seg_h(ren, x, y, 10);
    draw_seg_v(ren, x, y, 8);
    draw_seg_h(ren, x, y + 7, 10);
    draw_seg_v(ren, x + 8, y + 7, 9);
    draw_seg_h(ren, x, y + 14, 10);
}

/* ── HUD: "P: <count>  T: <time>s" ─────────────────────────────── */
static void draw_hud(SDL_Renderer* ren) {
    SDL_SetRenderDrawColor(ren, 0, 0, 0, 160);
    SDL_Rect bg = {8, 8, 260, 28};
    SDL_RenderFillRect(ren, &bg);

    SDL_SetRenderDrawColor(ren, 180, 220, 255, 255);
    draw_char_P(ren, 14, 14);
    draw_char_colon(ren, 26, 14);
    draw_number(ren, 34, 14, SPH_N);

    double sim_time = g_step * SPH_DT;
    int t_int  = (int)(sim_time * 100.0);
    int t_sec  = t_int / 100;
    int t_frac = t_int % 100;

    draw_char_T(ren, 100, 14);
    draw_char_colon(ren, 112, 14);
    draw_number(ren, 120, 14, t_sec);
    int ndig = 1;
    { int tmp = t_sec; while (tmp >= 10) { ++ndig; tmp /= 10; } }
    int dx = 120 + ndig * 12;
    draw_char_dot(ren, dx, 14);
    dx += 8;
    if (t_frac < 10) {
        draw_digit(ren, dx, 14, 0, 10, 16);
        dx += 12;
    }
    draw_number(ren, dx, 14, t_frac);
    int fdig = (t_frac < 10) ? 1 : ((t_frac < 100) ? 2 : 3);
    if (t_frac < 10) fdig = 2;
    dx += fdig * 12;
    draw_char_s(ren, dx, 14);
}

/* ── Draw bounding box walls ────────────────────────────────────── */
static void draw_walls(SDL_Renderer* ren) {
    SDL_SetRenderDrawColor(ren, 60, 80, 120, 255);
    int x0 = sx(0.0), y0 = sy(0.0);
    int x1 = sx(SPH_BOX), y1 = sy(SPH_BOX);
    SDL_Rect top    = {x0 - 2, y1 - 2, x1 - x0 + 4, 3};
    SDL_Rect bottom = {x0 - 2, y0,     x1 - x0 + 4, 3};
    SDL_Rect left   = {x0 - 2, y1 - 2, 3,            y0 - y1 + 4};
    SDL_Rect right  = {x1,     y1 - 2, 3,            y0 - y1 + 4};
    SDL_RenderFillRect(ren, &top);
    SDL_RenderFillRect(ren, &bottom);
    SDL_RenderFillRect(ren, &left);
    SDL_RenderFillRect(ren, &right);
}

/* ── Main ────────────────────────────────────────────────────────── */
int main(int argc, char** argv) {
    int max_frames = 0;
    int headless = 0;
    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--frames") == 0 && i + 1 < argc)
            max_frames = atoi(argv[++i]);
        else if (strcmp(argv[i], "--headless") == 0)
            headless = 1;
    }

    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
        return 1;
    }

    Uint32 wflags = headless ? SDL_WINDOW_HIDDEN : SDL_WINDOW_SHOWN;
    SDL_Window* win = SDL_CreateWindow(
        "Li World Studio \xe2\x80\x94 SPH Fluid Dynamics",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        WIN_W, WIN_H, wflags);
    if (!win) {
        fprintf(stderr, "SDL_CreateWindow: %s\n", SDL_GetError());
        SDL_Quit();
        return 2;
    }

    SDL_Renderer* ren = SDL_CreateRenderer(win, -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!ren)
        ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_SOFTWARE);
    if (!ren) {
        fprintf(stderr, "SDL_CreateRenderer: %s\n", SDL_GetError());
        SDL_DestroyWindow(win);
        SDL_Quit();
        return 3;
    }
    SDL_SetRenderDrawBlendMode(ren, SDL_BLENDMODE_BLEND);

    sph_init();

    int frame = 0;
    int running = 1;
    Uint32 t0 = SDL_GetTicks();

    while (running) {
        SDL_Event ev;
        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_QUIT) running = 0;
            if (ev.type == SDL_KEYDOWN && ev.key.keysym.sym == SDLK_ESCAPE)
                running = 0;
            if (ev.type == SDL_KEYDOWN && ev.key.keysym.sym == SDLK_r)
                sph_init();
        }

        for (int s = 0; s < SUBSTEPS; ++s)
            sph_step();

        /* Clear background fully each frame */
        SDL_SetRenderDrawColor(ren, BG_R, BG_G, BG_B, 255);
        SDL_RenderClear(ren);

        /* Metaball-like fluid layer: large semi-transparent circles.
           Three passes at decreasing radius / increasing opacity build
           a soft glow that merges where particles overlap. */
        for (int i = 0; i < SPH_N; ++i) {
            double speed = sqrt(g_p[i].v[0] * g_p[i].v[0] +
                                g_p[i].v[1] * g_p[i].v[1]);
            Uint8 cr, cg, cb;
            vel_color(speed, &cr, &cg, &cb);
            SDL_SetRenderDrawColor(ren,
                (Uint8)(cr * 0.25), (Uint8)(cg * 0.3), (Uint8)(cb * 0.5), 18);
            fill_circle(ren, sx(g_p[i].x[0]), sy(g_p[i].x[1]), 22);
        }

        for (int i = 0; i < SPH_N; ++i) {
            double speed = sqrt(g_p[i].v[0] * g_p[i].v[0] +
                                g_p[i].v[1] * g_p[i].v[1]);
            Uint8 cr, cg, cb;
            vel_color(speed, &cr, &cg, &cb);
            SDL_SetRenderDrawColor(ren,
                (Uint8)(cr * 0.5), (Uint8)(cg * 0.5), (Uint8)(cb * 0.7), 40);
            fill_circle(ren, sx(g_p[i].x[0]), sy(g_p[i].x[1]), 14);
        }

        for (int i = 0; i < SPH_N; ++i) {
            double speed = sqrt(g_p[i].v[0] * g_p[i].v[0] +
                                g_p[i].v[1] * g_p[i].v[1]);
            Uint8 cr, cg, cb;
            vel_color(speed, &cr, &cg, &cb);
            SDL_SetRenderDrawColor(ren, cr, cg, cb, 80);
            fill_circle(ren, sx(g_p[i].x[0]), sy(g_p[i].x[1]), 8);
        }

        /* Core particles: solid bright circles */
        for (int i = 0; i < SPH_N; ++i) {
            double speed = sqrt(g_p[i].v[0] * g_p[i].v[0] +
                                g_p[i].v[1] * g_p[i].v[1]);
            Uint8 cr, cg, cb;
            vel_color(speed, &cr, &cg, &cb);
            SDL_SetRenderDrawColor(ren, cr, cg, cb, 230);
            fill_circle(ren, sx(g_p[i].x[0]), sy(g_p[i].x[1]), 4);
        }

        draw_walls(ren);
        draw_hud(ren);

        SDL_RenderPresent(ren);
        ++frame;

        if (max_frames > 0 && frame >= max_frames) running = 0;

        if (frame % 60 == 0) {
            Uint32 elapsed = SDL_GetTicks() - t0;
            double fps = (double)frame / ((double)elapsed / 1000.0);
            printf("frame %d  sim_step %d  sim_time %.4fs  fps %.1f\n",
                   frame, g_step, g_step * SPH_DT, fps);
        }
    }

    Uint32 total = SDL_GetTicks() - t0;
    printf("Done: %d frames, %d sim steps, %.3f sim seconds, %.1f wall-ms\n",
           frame, g_step, g_step * SPH_DT, (double)total);

    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 0;
}
