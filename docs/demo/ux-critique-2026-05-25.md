# Li World Studio X demo — UX critique (research)

**Artifact:** `docs/demo/media/studio-x-demo.mp4` (~37s)  
**Capture:** HTML marketing mocks from `lic` `main` @ `98cdd7c` (playwright PNG → ffmpeg); **not** native `li-studio` / wgpu window.  
**Provenance:** `docs/demo/media/capture-provenance.json`  
**Vision baseline:** `lic/docs/game-dev/world-studio-vision.md` (PH-UX, PH-AGENT, PH-GD)

---

## What “latest dev” actually is (2026-05-25)

| Repo | Ref | Capturable UI today |
|------|-----|-------------------|
| **lic** `main` | `98cdd7c` | `deploy/studio-demo/` HTML + SDL grid stub (`native_pixels=false`) |
| **studio** `main` | `fd596b7` | `li-studio-demo` — headless compose/paint smoke only; no host window |
| **ui** | `970b8b0` | Agent dock / palette IR — consumed by studio compose, not screen-recordable alone |
| **render** | `2653f31` | wgpu smoke; `surface_ok=false`, honest HUD, no framebuffer export |
| **world** | `8db9b76` | `world.li` data — no editor chrome |

**Conclusion:** The X reel remains the **honest marketing-mock pipeline** until PH-GD-5 binds `lig.present` to a desktop shell. Native vertical tour (`lic/scripts/record-studio-verticals-demo.sh`) targets CPU present frames, not full chrome.

---

## Scene-by-scene analysis

### Scene 1 — Workspace with selection (0:00–0:10)

**Hierarchy:** Top mock banner → title/profile → viewport (largest) → agent strip → timeline → inspector. Viewport wins; agent strip competes with timeline for bottom attention.

**Agent dock:** Running state + last action + Cancel are visible. Missing: explicit input affordance (where the agent is *invoked*), task ID, proof/REQ trace, MCP tool name, or “open in Cursor” bridge. For goal-directed agents, status without **next action** or **editable plan** is weak.

**Viewport:** Grid + selection ring reads as “3D editor” but content is abstract (no `world.li` entity tree in view). HUD honestly states bench simulate / no native pixels — good for trust, harsh for X hook.

**Motion (X):** 10s static PNG — fine for VO; poor for scroll-stop without subtle parallax or playhead motion.

**vs vision:** Drug-design profile chip aligns with `sim_drug_design`; lacks outliner, `world.li` tab, command palette open state, or ≤3-click export path (PH-UX AM export N/A here).

### Scene 2 — Empty viewport (0:10–0:17)

**Hierarchy:** Empty-state CTA centered — clear primary action. Inspector and timeline secondary copy consistent.

**Agent dock:** “Idle — describe a task to start” is **one line of muted text** — no text field, send button, or `@` mention pattern. **P0 for agent-native positioning:** agents are narrated, not operable in the mock.

**Accessibility:** Low contrast idle copy; dock icons lack text labels (tooltips only in HTML `title`).

**vs vision:** Matches “text `world.li` scenes” narrative in script; missing outliner referenced in inspector hint.

### Scene 3 — Agent / render error (0:17–0:25)

**Hierarchy:** Error competes on three surfaces (viewport strip, full-width bar, inspector card) — **redundant**; good for “fail visible,” bad for “where do I act?”

**Trust:** Copy mirrors real stack (`wgpu surface_ok=false`, bench simulate) — **high honesty**, aligns with `render` README. Risk: X audience may read as “product is broken” unless VO/script frames as *recovery UX demo*.

**Recovery affordances:** Retry / Report logs / Dismiss exist visually but are non-functional HTML. Goal-directed workflow needs wired `lic_check` / log bundle / agent retry semantics (PH-AGENT).

**Motion:** 8s hold — appropriate for reading error text; needs VO to avoid doom-scroll interpretation.

### Scene 4–5 — CTA hold (0:25–0:37)

Duplicate workspace frame — reinforces brand but **no URL, logo, or CTA overlay** in pixels (relies entirely on post copy). For X, burn-in or end card would improve conversion.

---

## Prioritized findings (goal-directed agent workflows)

### P0

1. **Agent invoke surface absent** — idle/running states without input, plan, or tool trace; blocks “agents as first-class users” claim in vision §2.
2. **Mock ≠ product gap** — reel cannot show `li-studio-demo` compose or wgpu viewport; coordinators must label capture mode in every post (provenance JSON + banner).
3. **Error scene without recovery path** — buttons are decorative; agents cannot demonstrate `apply_patch` / retry loop from UI.

### P1

4. **Information redundancy on failure** — three error regions; consolidate to one primary strip + inspector detail (progressive disclosure).
5. **Dock icon-only tools** — fails WCAG 2.2 AA icon-only guidance in PH-UX; hurts discoverability for agent-triggered tools.
6. **No outliner / scene graph** — inspector references selection not visible in hierarchy; weak for `world.li` git-diff story.
7. **Static 37s reel** — no timeline playhead motion, agent pulse, or viewport orbit; underuses X motion affordances.

### P2

8. **Profile chip without switcher** — “Drug design” / “No profile” not tied to `sim_set_profile` agent tool story.
9. **Command palette never opens** — ⌘K hint only; missed ≤3-click / keyboard-first PH-UX beat.
10. **End CTA not in-frame** — depends on bio link; add optional ffmpeg end card when libfreetype available.
11. **Chrome `--screenshot` hang on macOS** — recorder must use playwright path (documented in `RECORDING.md`).

---

## Gaps vs `world-studio-vision.md`

| Vision target | Demo shows | Gap |
|---------------|------------|-----|
| PH-UX ≥60 fps viewport | HUD “60 (bench simulate)” | No real fps / native_pixels |
| PH-UX panel switch &lt;100 ms | Not demonstrated | N/A in static mock |
| PH-AGENT MCP tools | No tool names / outcomes | Narrative only |
| PH-GD-1 MVP viewport + outliner | Grid stub, no outliner | Major |
| `world.li` in git | Copy only | No file tree / diff |
| One engine profiles | Chip labels only | No `studio.toml` / profile switch |

---

## Recorder / stack recommendations

1. Keep **mock banner** in all HTML captures (already present).
2. Default `LIC_STUDIO_BRANCH=origin/main`; `STUDIO_DEMO_REFRESH=1` when tokens/HTML change.
3. Use **playwright** capture on macOS (`scripts/capture-studio-demo-png.mjs`); reserve Chrome `--screenshot` for Linux CI with timeout + continue.
4. When `li-studio` host window exists: `screencapture` or `record-studio-x-demo-native.sh` variant; retire HTML for X **only** after PH-GD-5 proof in provenance.
5. Optional: add 4th scene from `archive/verticals-html-mocks/` for profile tour (separate `studio-verticals-demo.mp4` on lic).

---

## Wave 2 addressed (studio-ux-19, 2026-05-25)

**Reel:** `docs/demo/media/studio-x-demo.mp4` (~38s) — five scenes from `lic` `deploy/studio-demo` Wave 2 HTML (`01`–`05`).  
**Provenance:** `capture-provenance.json` with `wave: 2` and scene list including `04-studio-command-palette`, `05-studio-end-cta`.

| Critique item (pre-Wave 2) | Wave 2 mock / reel change | Still open |
|----------------------------|---------------------------|------------|
| P0 Agent invoke absent | `02` task input + Send; `01` running + `lic_build` tool trace | Native `li-studio` compose wiring (PH-AGENT) |
| P0 Error recovery decorative | `03` Retry / Report logs / Dismiss + mock JS toasts/modal | Real `lic_check` / log bundle in product |
| P1 No outliner | `01`/`02` outliner column + selection sync copy | Native scene graph / `world.li` tree |
| P1 Triplicate error UI | Single `agent-error-strip`; inspector detail only | Compose error model in `li-studio` |
| P1 Dock icon-only | Dock text labels on `01` | Full WCAG in native chrome |
| P2 Palette never opens | `04` full-screen ⌘K palette scene in reel | Native palette &lt;100 ms (PH-UX) |
| P1 Static reel | CSS motion on `01` (`data-reel-motion`); 5-beat timeline | Native playhead / viewport motion |
| P2 End CTA not in-frame | `05` end card with URL placeholder | Optional ffmpeg burn-in when libfreetype available |
| **P0 Mock ≠ product** | Mock banner + provenance `native_window: false` | **PH-GD-5** wgpu host window — **unchanged** |

**Assessment (target):** UX-06 agent chrome and UX-08 error recovery should read stronger in the next plan-loop iteration report; UX-12 mock honesty remains 3.0 with explicit capture mode.

---

## Evidence commands

```bash
# Regenerate reel (studio repo)
STUDIO_DEMO_REFRESH=1 ./scripts/record-studio-x-demo.sh
ffprobe -show_entries format=duration docs/demo/media/studio-x-demo.mp4

# Frame grabs
ffmpeg -i docs/demo/media/studio-x-demo.mp4 -vf "select=eq(n\,0)" -vframes 1 /tmp/s1.png
```
