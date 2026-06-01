/*
 * Li World Studio — Real-time Molecular Dynamics Demo
 *
 * Lennard-Jones fluid: 256 particles, periodic boundaries, velocity Verlet.
 * Physics adapted from benchmarks/tier2_physics/md_lennard_jones/common/md_core.h
 *
 * Build:
 *   clang-22 -O2 demos/md_molecular_demo.c -o demos/md_molecular_demo \
 *            -lSDL2 -lm -I/usr/include/SDL2
 *
 * Controls: ESC = quit, SPACE = pause, R = reset, UP/DOWN = heat/cool
 * Env:      MD_DEMO_FRAMES=N  auto-quit after N rendered frames.
 */

#include <SDL.h>
#include <math.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

/* ═══════════════════════════════════════════════════════════════════════
 * Physics constants (LJ reduced units, from md_core.h)
 * ═══════════════════════════════════════════════════════════════════════ */
#define MD_N    256
#define MD_DT   0.004
#define MD_RC   2.5
#define MD_BOX  10.0
#define MD_TEMP 1.0
#define MD_SEED UINT64_C(7)

/* ═══════════════════════════════════════════════════════════════════════
 * Display constants
 * ═══════════════════════════════════════════════════════════════════════ */
#define WIN_W           1200
#define WIN_H           900
#define SIM_PAD         50
#define SIM_SIDE        (WIN_H - 2 * SIM_PAD)
#define SIM_LEFT        ((WIN_W - SIM_SIDE) / 2)
#define SIM_TOP         SIM_PAD
#define PX_PER_UNIT     ((double)SIM_SIDE / MD_BOX)
#define GLOW_R          16
#define GLOW_D          (GLOW_R * 2)
#define STEPS_PER_FRAME 8
#define TARGET_FPS      60
#define FADE_ALPHA      28

/* ═══════════════════════════════════════════════════════════════════════
 * Physics types (from md_core.h)
 * ═══════════════════════════════════════════════════════════════════════ */
typedef struct { uint64_t state; } MdRng;

typedef struct {
    double px[MD_N], py[MD_N], pz[MD_N];
    double vx[MD_N], vy[MD_N], vz[MD_N];
    double fx[MD_N], fy[MD_N], fz[MD_N];
} MdState;

/* ═══════════════════════════════════════════════════════════════════════
 * RNG — PCG-style LCG (from md_core.h)
 * ═══════════════════════════════════════════════════════════════════════ */
static void rng_init(MdRng *r, uint64_t seed) { r->state = seed; }

static double rng_uniform(MdRng *r) {
    r->state = r->state * UINT64_C(6364136223846793005) + UINT64_C(1);
    return (double)(r->state >> 11) / (double)(1ULL << 53);
}

static double rng_normal(MdRng *r) {
    double u1 = rng_uniform(r);
    if (u1 < 1e-12) u1 = 1e-12;
    double u2 = rng_uniform(r);
    return sqrt(-2.0 * log(u1)) * cos(2.0 * 3.14159265358979323846 * u2);
}

/* ═══════════════════════════════════════════════════════════════════════
 * Observables
 * ═══════════════════════════════════════════════════════════════════════ */
static void md_kinetic(const MdState *s, double *ke) {
    double e = 0.0;
    for (int i = 0; i < MD_N; i++)
        e += s->vx[i]*s->vx[i] + s->vy[i]*s->vy[i] + s->vz[i]*s->vz[i];
    *ke = 0.5 * e;
}

static void md_potential(const MdState *s, double *pe) {
    const double rc2 = MD_RC * MD_RC, half = 0.5 * MD_BOX;
    double e = 0.0;
    for (int i = 0; i < MD_N; i++) {
        for (int j = i + 1; j < MD_N; j++) {
            double dx = s->px[j] - s->px[i];
            double dy = s->py[j] - s->py[i];
            double dz = s->pz[j] - s->pz[i];
            if (dx >  half) dx -= MD_BOX; else if (dx < -half) dx += MD_BOX;
            if (dy >  half) dy -= MD_BOX; else if (dy < -half) dy += MD_BOX;
            if (dz >  half) dz -= MD_BOX; else if (dz < -half) dz += MD_BOX;
            double r2 = dx*dx + dy*dy + dz*dz;
            if (r2 >= rc2 || r2 < 1e-12) continue;
            double ir2 = 1.0 / r2, ir6 = ir2 * ir2 * ir2;
            e += 4.0 * (ir6 * ir6 - ir6);
        }
    }
    *pe = e;
}

/* ═══════════════════════════════════════════════════════════════════════
 * Initialization: FCC lattice + Maxwell-Boltzmann velocities
 * ═══════════════════════════════════════════════════════════════════════ */
static void md_init(MdState *s, MdRng *rng) {
    static const double basis[4][3] = {
        {0, 0, 0}, {0, 0.5, 0.5}, {0.5, 0, 0.5}, {0.5, 0.5, 0}
    };
    int nc = 1;
    while (4 * nc * nc * nc < MD_N) nc++;
    double a = MD_BOX / (double)nc;
    int idx = 0;
    for (int ix = 0; ix < nc && idx < MD_N; ix++)
        for (int iy = 0; iy < nc && idx < MD_N; iy++)
            for (int iz = 0; iz < nc && idx < MD_N; iz++)
                for (int b = 0; b < 4 && idx < MD_N; b++, idx++) {
                    s->px[idx] = ((double)ix + basis[b][0]) * a;
                    s->py[idx] = ((double)iy + basis[b][1]) * a;
                    s->pz[idx] = ((double)iz + basis[b][2]) * a;
                }
    double sc = sqrt(MD_TEMP);
    for (int i = 0; i < MD_N; i++) {
        s->vx[i] = sc * rng_normal(rng);
        s->vy[i] = sc * rng_normal(rng);
        s->vz[i] = sc * rng_normal(rng);
    }
    double sx = 0, sy = 0, sz = 0;
    for (int i = 0; i < MD_N; i++) {
        sx += s->vx[i]; sy += s->vy[i]; sz += s->vz[i];
    }
    double inv = 1.0 / (double)MD_N;
    for (int i = 0; i < MD_N; i++) {
        s->vx[i] -= sx * inv;
        s->vy[i] -= sy * inv;
        s->vz[i] -= sz * inv;
    }
    double ke;
    md_kinetic(s, &ke);
    double target = 1.5 * (double)MD_N * MD_TEMP;
    if (ke > 1e-20) {
        double f = sqrt(target / ke);
        for (int i = 0; i < MD_N; i++) {
            s->vx[i] *= f; s->vy[i] *= f; s->vz[i] *= f;
        }
    }
}

/* ═══════════════════════════════════════════════════════════════════════
 * Minimum-image convention & periodic wrapping
 * ═══════════════════════════════════════════════════════════════════════ */
static double md_mic(double d) {
    const double half = 0.5 * MD_BOX;
    if (d >  half) return d - MD_BOX;
    if (d < -half) return d + MD_BOX;
    return d;
}

static double md_wrap(double x) {
    x = fmod(x, MD_BOX);
    if (x < 0.0) x += MD_BOX;
    return x;
}

/* ═══════════════════════════════════════════════════════════════════════
 * Forces: LJ 12-6 all-pairs with cutoff (from md_core.h)
 * ═══════════════════════════════════════════════════════════════════════ */
static void md_forces(MdState *s) {
    const double rc2 = MD_RC * MD_RC;
    memset(s->fx, 0, sizeof(s->fx));
    memset(s->fy, 0, sizeof(s->fy));
    memset(s->fz, 0, sizeof(s->fz));
    for (int i = 0; i < MD_N; i++) {
        for (int j = i + 1; j < MD_N; j++) {
            double dx = md_mic(s->px[j] - s->px[i]);
            double dy = md_mic(s->py[j] - s->py[i]);
            double dz = md_mic(s->pz[j] - s->pz[i]);
            double r2 = dx*dx + dy*dy + dz*dz;
            if (r2 >= rc2 || r2 < 1e-12) continue;
            double ir2 = 1.0 / r2;
            double ir6 = ir2 * ir2 * ir2;
            double ir12 = ir6 * ir6;
            double f = 48.0 * ir12 - 24.0 * ir6;
            s->fx[i] -= f * dx; s->fy[i] -= f * dy; s->fz[i] -= f * dz;
            s->fx[j] += f * dx; s->fy[j] += f * dy; s->fz[j] += f * dz;
        }
    }
}

/* ═══════════════════════════════════════════════════════════════════════
 * Velocity-Verlet integrator step (from md_core.h)
 * ═══════════════════════════════════════════════════════════════════════ */
static void md_step(MdState *s) {
    for (int i = 0; i < MD_N; i++) {
        s->vx[i] += 0.5 * MD_DT * s->fx[i];
        s->vy[i] += 0.5 * MD_DT * s->fy[i];
        s->vz[i] += 0.5 * MD_DT * s->fz[i];
    }
    for (int i = 0; i < MD_N; i++) {
        s->px[i] = md_wrap(s->px[i] + MD_DT * s->vx[i]);
        s->py[i] = md_wrap(s->py[i] + MD_DT * s->vy[i]);
        s->pz[i] = md_wrap(s->pz[i] + MD_DT * s->vz[i]);
    }
    md_forces(s);
    for (int i = 0; i < MD_N; i++) {
        s->vx[i] += 0.5 * MD_DT * s->fx[i];
        s->vy[i] += 0.5 * MD_DT * s->fy[i];
        s->vz[i] += 0.5 * MD_DT * s->fz[i];
    }
}

/* ═══════════════════════════════════════════════════════════════════════
 * Velocity → color ramp (blue → cyan → green → orange → red)
 * ═══════════════════════════════════════════════════════════════════════ */
static void velocity_color(double vmag, uint8_t *r, uint8_t *g, uint8_t *b) {
    double t = vmag / 4.0;
    if (t > 1.0) t = 1.0;
    if (t < 0.0) t = 0.0;

    if (t < 0.25) {
        double s = t / 0.25;
        *r = (uint8_t)(30);
        *g = (uint8_t)(80  + 175 * s);
        *b = (uint8_t)(220 +  35 * s);
    } else if (t < 0.5) {
        double s = (t - 0.25) / 0.25;
        *r = (uint8_t)(30  +  80 * s);
        *g = 255;
        *b = (uint8_t)(255 - 200 * s);
    } else if (t < 0.75) {
        double s = (t - 0.5) / 0.25;
        *r = (uint8_t)(110 + 145 * s);
        *g = (uint8_t)(255 - 100 * s);
        *b = (uint8_t)( 55 -  55 * s);
    } else {
        double s = (t - 0.75) / 0.25;
        *r = 255;
        *g = (uint8_t)(155 - 125 * s);
        *b = (uint8_t)(30 * s);
    }
}

/* ═══════════════════════════════════════════════════════════════════════
 * Minimal 5×7 bitmap font (digits, select letters, punctuation)
 * Rendered as scaled filled-rectangles — no SDL_ttf required.
 * ═══════════════════════════════════════════════════════════════════════ */
#define FW 5
#define FH 7

static const uint8_t font_glyphs[][FH] = {
    /* 0  */ {0x0E,0x11,0x11,0x11,0x11,0x11,0x0E},
    /* 1  */ {0x04,0x0C,0x04,0x04,0x04,0x04,0x0E},
    /* 2  */ {0x0E,0x11,0x01,0x06,0x08,0x10,0x1F},
    /* 3  */ {0x0E,0x11,0x01,0x06,0x01,0x11,0x0E},
    /* 4  */ {0x02,0x06,0x0A,0x12,0x1F,0x02,0x02},
    /* 5  */ {0x1F,0x10,0x1E,0x01,0x01,0x11,0x0E},
    /* 6  */ {0x06,0x08,0x10,0x1E,0x11,0x11,0x0E},
    /* 7  */ {0x1F,0x01,0x02,0x04,0x08,0x08,0x08},
    /* 8  */ {0x0E,0x11,0x11,0x0E,0x11,0x11,0x0E},
    /* 9  */ {0x0E,0x11,0x11,0x0F,0x01,0x02,0x0C},
    /* E  */ {0x1F,0x10,0x10,0x1E,0x10,0x10,0x1F},
    /* K  */ {0x11,0x12,0x14,0x18,0x14,0x12,0x11},
    /* M  */ {0x11,0x1B,0x15,0x11,0x11,0x11,0x11},
    /* N  */ {0x11,0x19,0x15,0x13,0x11,0x11,0x11},
    /* P  */ {0x1E,0x11,0x11,0x1E,0x10,0x10,0x10},
    /* S  */ {0x0E,0x11,0x10,0x0E,0x01,0x11,0x0E},
    /* T  */ {0x1F,0x04,0x04,0x04,0x04,0x04,0x04},
    /* .  */ {0x00,0x00,0x00,0x00,0x00,0x0C,0x0C},
    /* -  */ {0x00,0x00,0x00,0x0E,0x00,0x00,0x00},
    /* :  */ {0x00,0x0C,0x0C,0x00,0x0C,0x0C,0x00},
    /* sp */ {0x00,0x00,0x00,0x00,0x00,0x00,0x00},
};

static int glyph_idx(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    switch (c) {
        case 'E': case 'e': return 10;
        case 'K': case 'k': return 11;
        case 'M': case 'm': return 12;
        case 'N': case 'n': return 13;
        case 'P': case 'p': return 14;
        case 'S': case 's': return 15;
        case 'T': case 't': return 16;
        case '.':           return 17;
        case '-':           return 18;
        case ':':           return 19;
        default:            return 20;
    }
}

static void draw_text(SDL_Renderer *ren, int x, int y, const char *str,
                      int scale, uint8_t r, uint8_t g, uint8_t b) {
    SDL_SetRenderDrawColor(ren, r, g, b, 255);
    for (; *str; str++, x += (FW + 1) * scale) {
        int gi = glyph_idx(*str);
        const uint8_t *glyph = font_glyphs[gi];
        for (int row = 0; row < FH; row++) {
            uint8_t bits = glyph[row];
            for (int col = 0; col < FW; col++) {
                if (bits & (1 << (FW - 1 - col))) {
                    SDL_Rect px = {x + col * scale, y + row * scale, scale, scale};
                    SDL_RenderFillRect(ren, &px);
                }
            }
        }
    }
}

/* ═══════════════════════════════════════════════════════════════════════
 * Glow texture: white circle with gaussian alpha falloff
 * ═══════════════════════════════════════════════════════════════════════ */
static SDL_Texture *create_glow(SDL_Renderer *ren) {
    SDL_Surface *sf = SDL_CreateRGBSurface(
        0, GLOW_D, GLOW_D, 32,
        0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000);
    if (!sf) return NULL;
    SDL_LockSurface(sf);
    uint32_t *pix = (uint32_t *)sf->pixels;
    int pitch = sf->pitch / 4;
    for (int y = 0; y < GLOW_D; y++) {
        for (int x = 0; x < GLOW_D; x++) {
            double dx = ((double)x - GLOW_R + 0.5) / GLOW_R;
            double dy = ((double)y - GLOW_R + 0.5) / GLOW_R;
            double d2 = dx * dx + dy * dy;
            uint8_t a = 0;
            if (d2 < 1.0)
                a = (uint8_t)(exp(-3.0 * d2) * 255.0);
            pix[y * pitch + x] = SDL_MapRGBA(sf->format, 255, 255, 255, a);
        }
    }
    SDL_UnlockSurface(sf);
    SDL_Texture *tex = SDL_CreateTextureFromSurface(ren, sf);
    SDL_FreeSurface(sf);
    if (tex)
        SDL_SetTextureBlendMode(tex, SDL_BLENDMODE_ADD);
    return tex;
}

/* ═══════════════════════════════════════════════════════════════════════
 * Draw simulation-box grid
 * ═══════════════════════════════════════════════════════════════════════ */
static void draw_grid(SDL_Renderer *ren) {
    SDL_SetRenderDrawBlendMode(ren, SDL_BLENDMODE_BLEND);
    SDL_SetRenderDrawColor(ren, 0x1a, 0x1a, 0x30, 55);
    for (int i = 0; i <= (int)MD_BOX; i++) {
        int gx = SIM_LEFT + (int)(i * PX_PER_UNIT);
        int gy = SIM_TOP  + (int)(i * PX_PER_UNIT);
        SDL_RenderDrawLine(ren, gx, SIM_TOP, gx, SIM_TOP + SIM_SIDE);
        SDL_RenderDrawLine(ren, SIM_LEFT, gy, SIM_LEFT + SIM_SIDE, gy);
    }
    SDL_SetRenderDrawColor(ren, 0x2a, 0x3a, 0x5a, 180);
    SDL_Rect border = {SIM_LEFT, SIM_TOP, SIM_SIDE, SIM_SIDE};
    SDL_RenderDrawRect(ren, &border);
}

/* ═══════════════════════════════════════════════════════════════════════
 * Draw HUD panel (energy bars + stats, no SDL_ttf)
 * ═══════════════════════════════════════════════════════════════════════ */
static void draw_hud(SDL_Renderer *ren, int sim_step, double ke, double pe,
                     double temperature) {
    const int hx = 12, hy = 12, hw = 195, hh = 230;
    const int bar_w = 150, bar_h = 10;
    const int fs = 2;

    SDL_SetRenderDrawBlendMode(ren, SDL_BLENDMODE_BLEND);
    SDL_SetRenderDrawColor(ren, 0x05, 0x05, 0x10, 190);
    SDL_Rect bg = {hx, hy, hw, hh};
    SDL_RenderFillRect(ren, &bg);
    SDL_SetRenderDrawColor(ren, 0x2a, 0x3a, 0x5a, 200);
    SDL_RenderDrawRect(ren, &bg);

    int cy = hy + 10;
    draw_text(ren, hx + 8, cy, "STEP", fs, 0x70, 0x80, 0xA0);
    char buf[32];
    snprintf(buf, sizeof(buf), "%d", sim_step);
    draw_text(ren, hx + 68, cy, buf, fs, 0xC0, 0xD0, 0xE0);

    /* KE bar */
    cy += 30;
    draw_text(ren, hx + 8, cy, "KE", fs, 0xFF, 0x80, 0x30);
    snprintf(buf, sizeof(buf), "%.0f", ke);
    draw_text(ren, hx + 8 + 42, cy, buf, fs, 0xFF, 0xA0, 0x50);
    cy += 18;
    double ke_frac = ke / 600.0;
    if (ke_frac > 1.0) ke_frac = 1.0;
    SDL_SetRenderDrawColor(ren, 0xFF, 0x80, 0x30, 200);
    SDL_Rect kb = {hx + 8, cy, (int)(bar_w * ke_frac), bar_h};
    SDL_RenderFillRect(ren, &kb);
    SDL_SetRenderDrawColor(ren, 0x40, 0x30, 0x20, 100);
    SDL_Rect kbg = {hx + 8, cy, bar_w, bar_h};
    SDL_RenderDrawRect(ren, &kbg);

    /* PE bar (show absolute value) */
    cy += 20;
    draw_text(ren, hx + 8, cy, "PE", fs, 0x40, 0x80, 0xFF);
    snprintf(buf, sizeof(buf), "%.0f", pe);
    draw_text(ren, hx + 8 + 42, cy, buf, fs, 0x60, 0xA0, 0xFF);
    cy += 18;
    double pe_abs = pe < 0 ? -pe : pe;
    double pe_frac = pe_abs / 1200.0;
    if (pe_frac > 1.0) pe_frac = 1.0;
    SDL_SetRenderDrawColor(ren, 0x40, 0x80, 0xFF, 200);
    SDL_Rect pb = {hx + 8, cy, (int)(bar_w * pe_frac), bar_h};
    SDL_RenderFillRect(ren, &pb);
    SDL_SetRenderDrawColor(ren, 0x20, 0x30, 0x50, 100);
    SDL_Rect pbg = {hx + 8, cy, bar_w, bar_h};
    SDL_RenderDrawRect(ren, &pbg);

    /* Temperature gradient bar */
    cy += 22;
    draw_text(ren, hx + 8, cy, "TEMP", fs, 0xFF, 0xFF, 0x60);
    snprintf(buf, sizeof(buf), "%.2f", temperature);
    draw_text(ren, hx + 8 + 66, cy, buf, fs, 0xFF, 0xFF, 0x90);
    cy += 18;
    double t_frac = temperature / 3.0;
    if (t_frac > 1.0) t_frac = 1.0;
    int t_pixels = (int)(bar_w * t_frac);
    for (int bx = 0; bx < t_pixels; bx++) {
        double bt = (double)bx / (double)bar_w;
        uint8_t tr = (uint8_t)(bt * 255);
        uint8_t tg = (uint8_t)((1.0 - bt * 0.6) * 200);
        uint8_t tb = (uint8_t)((1.0 - bt) * 255);
        SDL_SetRenderDrawColor(ren, tr, tg, tb, 220);
        SDL_Rect tc = {hx + 8 + bx, cy, 1, bar_h};
        SDL_RenderFillRect(ren, &tc);
    }
    SDL_SetRenderDrawColor(ren, 0x30, 0x30, 0x40, 100);
    SDL_Rect tbg = {hx + 8, cy, bar_w, bar_h};
    SDL_RenderDrawRect(ren, &tbg);

    /* Particle count */
    cy += 20;
    draw_text(ren, hx + 8, cy, "N", fs, 0x70, 0x80, 0xA0);
    snprintf(buf, sizeof(buf), "%d", MD_N);
    draw_text(ren, hx + 8 + 18, cy, buf, fs, 0xC0, 0xD0, 0xE0);
}

/* ═══════════════════════════════════════════════════════════════════════
 * Main
 * ═══════════════════════════════════════════════════════════════════════ */
int main(int argc, char *argv[]) {
    (void)argc; (void)argv;

    int max_frames = 0;
    const char *fl = getenv("MD_DEMO_FRAMES");
    if (fl && fl[0]) max_frames = atoi(fl);

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Window *win = SDL_CreateWindow(
        "Li World Studio \xe2\x80\x94 Molecular Dynamics",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        WIN_W, WIN_H, SDL_WINDOW_SHOWN);
    if (!win) {
        fprintf(stderr, "SDL_CreateWindow: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    SDL_Renderer *ren = SDL_CreateRenderer(win, -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_TARGETTEXTURE);
    if (!ren)
        ren = SDL_CreateRenderer(win, -1,
            SDL_RENDERER_SOFTWARE | SDL_RENDERER_TARGETTEXTURE);
    if (!ren) {
        fprintf(stderr, "SDL_CreateRenderer: %s\n", SDL_GetError());
        SDL_DestroyWindow(win);
        SDL_Quit();
        return 1;
    }

    /* Glow texture for particle rendering */
    SDL_Texture *glow = create_glow(ren);
    if (!glow) {
        fprintf(stderr, "create_glow failed\n");
        SDL_DestroyRenderer(ren);
        SDL_DestroyWindow(win);
        SDL_Quit();
        return 1;
    }

    /* Trail render-target texture */
    SDL_Texture *trail = SDL_CreateTexture(ren,
        SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_TARGET, WIN_W, WIN_H);
    if (!trail) {
        fprintf(stderr, "Trail texture: %s\n", SDL_GetError());
        SDL_DestroyTexture(glow);
        SDL_DestroyRenderer(ren);
        SDL_DestroyWindow(win);
        SDL_Quit();
        return 1;
    }
    SDL_SetTextureBlendMode(trail, SDL_BLENDMODE_BLEND);

    /* Initialize trail to background color */
    SDL_SetRenderTarget(ren, trail);
    SDL_SetRenderDrawColor(ren, 0x0a, 0x0a, 0x1a, 255);
    SDL_RenderClear(ren);
    SDL_SetRenderTarget(ren, NULL);

    /* Initialize physics */
    MdRng rng;
    MdState state;
    rng_init(&rng, MD_SEED);
    md_init(&state, &rng);
    md_forces(&state);

    int sim_step = 0;
    int paused = 0;
    int running = 1;
    int frame_count = 0;
    Uint32 frame_start;

    printf("MD Demo: %d particles, box=%.1f, T=%.1f, dt=%.4f\n",
           MD_N, MD_BOX, MD_TEMP, MD_DT);
    printf("Controls: SPACE=pause, R=reset, UP/DOWN=heat/cool, ESC=quit\n");

    while (running) {
        frame_start = SDL_GetTicks();

        /* ─── Events ─── */
        SDL_Event ev;
        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_QUIT) {
                running = 0;
            } else if (ev.type == SDL_KEYDOWN) {
                switch (ev.key.keysym.sym) {
                case SDLK_ESCAPE:
                case SDLK_q:
                    running = 0;
                    break;
                case SDLK_SPACE:
                    paused = !paused;
                    break;
                case SDLK_r:
                    rng_init(&rng, MD_SEED);
                    md_init(&state, &rng);
                    md_forces(&state);
                    sim_step = 0;
                    break;
                case SDLK_UP: {
                    double ke;
                    md_kinetic(&state, &ke);
                    double f = 1.1;
                    for (int i = 0; i < MD_N; i++) {
                        state.vx[i] *= f;
                        state.vy[i] *= f;
                        state.vz[i] *= f;
                    }
                    break;
                }
                case SDLK_DOWN: {
                    double f = 0.9;
                    for (int i = 0; i < MD_N; i++) {
                        state.vx[i] *= f;
                        state.vy[i] *= f;
                        state.vz[i] *= f;
                    }
                    break;
                }
                default: break;
                }
            }
        }

        /* ─── Physics ─── */
        if (!paused) {
            for (int s = 0; s < STEPS_PER_FRAME; s++) {
                md_step(&state);
                sim_step++;
            }
        }

        /* ─── Compute observables ─── */
        double ke, pe;
        md_kinetic(&state, &ke);
        md_potential(&state, &pe);
        double temperature = (2.0 * ke) / (3.0 * (double)MD_N);

        /* ═══════════════════════════════════════════════════════════════
         * Render to trail texture (fade + grid + particles)
         * ═══════════════════════════════════════════════════════════════ */
        SDL_SetRenderTarget(ren, trail);

        /* Fade overlay — dims old content toward background */
        SDL_SetRenderDrawBlendMode(ren, SDL_BLENDMODE_BLEND);
        SDL_SetRenderDrawColor(ren, 0x0a, 0x0a, 0x1a, FADE_ALPHA);
        SDL_Rect full = {0, 0, WIN_W, WIN_H};
        SDL_RenderFillRect(ren, &full);

        /* Grid lines */
        draw_grid(ren);

        /* Particles — additive glow with velocity coloring */
        for (int i = 0; i < MD_N; i++) {
            double sx = SIM_LEFT + state.px[i] * PX_PER_UNIT;
            double sy = SIM_TOP  + state.py[i] * PX_PER_UNIT;

            double depth = state.pz[i] / MD_BOX;
            double size_f = 0.7 + 0.6 * depth;
            int rad = (int)(GLOW_R * size_f);

            double vmag = sqrt(
                state.vx[i]*state.vx[i] +
                state.vy[i]*state.vy[i] +
                state.vz[i]*state.vz[i]);
            uint8_t cr, cg, cb;
            velocity_color(vmag, &cr, &cg, &cb);

            uint8_t alpha = (uint8_t)(100 + 155 * depth);

            SDL_SetTextureColorMod(glow, cr, cg, cb);
            SDL_SetTextureAlphaMod(glow, alpha);
            SDL_Rect dst = {(int)(sx - rad), (int)(sy - rad), rad * 2, rad * 2};
            SDL_RenderCopy(ren, glow, NULL, &dst);

            /* Bright core dot */
            SDL_SetRenderDrawBlendMode(ren, SDL_BLENDMODE_BLEND);
            SDL_SetRenderDrawColor(ren, cr, cg, cb, (uint8_t)(160 + 95 * depth));
            int core = (int)(2 * size_f + 0.5);
            if (core < 1) core = 1;
            SDL_Rect dot = {(int)(sx - core), (int)(sy - core), core * 2, core * 2};
            SDL_RenderFillRect(ren, &dot);
        }

        /* ═══════════════════════════════════════════════════════════════
         * Composite trail to screen + HUD overlay
         * ═══════════════════════════════════════════════════════════════ */
        SDL_SetRenderTarget(ren, NULL);
        SDL_SetRenderDrawColor(ren, 0x0a, 0x0a, 0x1a, 255);
        SDL_RenderClear(ren);

        SDL_SetTextureBlendMode(trail, SDL_BLENDMODE_NONE);
        SDL_RenderCopy(ren, trail, NULL, NULL);

        draw_hud(ren, sim_step, ke, pe, temperature);

        SDL_RenderPresent(ren);

        /* ─── Frame limiting ─── */
        Uint32 elapsed = SDL_GetTicks() - frame_start;
        Uint32 target = 1000 / TARGET_FPS;
        if (elapsed < target)
            SDL_Delay(target - elapsed);

        frame_count++;
        if (max_frames > 0 && frame_count >= max_frames)
            running = 0;
    }

    printf("Exiting after %d frames (%d sim steps).\n", frame_count, sim_step);

    SDL_DestroyTexture(trail);
    SDL_DestroyTexture(glow);
    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 0;
}
