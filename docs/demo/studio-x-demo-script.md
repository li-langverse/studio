# Li World Studio — X demo script (~38s)

**Audience:** X (Twitter) — technical builders, game/sim engineers, agent-native tooling curious.  
**Visual source:** Marketing mocks from `lic` **`deploy/studio-demo`** (Wave 2: five HTML scenes). **Not** the shipped native `li-studio` window — production stack is `studio` + `ui` + `render` (`lig`/wgpu); `li-studio-demo` is headless compose/paint only.  
**Video artifact:** `docs/demo/media/studio-x-demo.mp4` + `capture-provenance.json` (SHAs, capture mode, `wave: 2`).  
**Regenerate:** `STUDIO_DEMO_REFRESH=1 LIC_STUDIO_BRANCH=origin/main ./scripts/record-studio-x-demo.sh` (after lic Wave 2 merges to `main`).

---

## On-screen beats (video timeline)

| Time | Scene | Visual |
|------|-------|--------|
| 0:00–0:08 | **Hook** | Workspace — outliner, dock labels, running agent + tool trace |
| 0:08–0:14 | **Beat 1** | Empty viewport — agent task input + Send, idle MCP hint |
| 0:14–0:19 | **Beat 2** | Command palette open (⌘K) — focus / agent / profile commands |
| 0:19–0:26 | **Beat 3** | Agent error strip — Retry, Report logs, Dismiss (single primary strip) |
| 0:26–0:38 | **CTA** | In-frame end card — logo, tagline, `li-langverse.github.io/studio` |

---

## Voiceover (read at ~140 wpm; ~38s total)

**[0:00 — Hook]**  
"What if your game engine editor was built for agents first — and still provable?"

**[0:08 — Beat 1]**  
"Li World Studio: text `world.li` scenes, scene outliner, and an agent dock you can actually invoke — not bolt-on AI."

**[0:14 — Beat 2]**  
"⌘K command palette for focus, agents, and profiles — keyboard-first, three clicks or fewer."

**[0:19 — Beat 3]**  
"When render or agents fail, one honest error strip — retry, report logs, dismiss — stay in flow."

**[0:26 — CTA]**  
"We're building it in the open on Li Engine. Follow **@li_langverse** — **li-langverse.github.io/studio**."

---

## Post copy (X)

**Option A (short)**  
Agent-native world editor on a provable engine. Outliner · ⌘K palette · recovery-first agents.  
→ li-langverse.github.io/studio  
#LiLang #gamedev #simulation

**Option B (thread hook)**  
UE/Unity hide your scene graph. Li World Studio keeps `world.li` in git and treats Cursor agents as first-class users.  
38s Wave 2 preview 👇 [attach `studio-x-demo.mp4`]

---

## Recording notes

- Rebuild video: `./scripts/record-studio-x-demo.sh` (from repo root).  
- Scene order is defined in `scripts/record-studio-x-demo.sh` (`ffmpeg-scenes.txt`).  
- macOS: prefer Playwright (`node scripts/capture-studio-demo-png.mjs`); Chrome `--screenshot` may hang on scene 04+ — see `docs/demo/RECORDING.md`.  
- Native viewport capture (SDL grid stub) needs a display; do not claim native UI until PH-GD-5 provenance shows `native_window: true`.
