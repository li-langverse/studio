# Studio X demo redo (lic main + playwright capture)

## Summary

Regenerates `studio-x-demo.mp4` from `lic` `main` `deploy/studio-demo` HTML mocks using playwright PNG capture (macOS Chrome `--screenshot` hang workaround), adds provenance JSON and UX research critique.

## Agent continuation

1. **Read** — `docs/demo/ux-critique-2026-05-25.md`, `docs/demo/media/capture-provenance.json`, `docs/demo/RECORDING.md`.
2. **Run** — `STUDIO_DEMO_REFRESH=1 ./scripts/record-studio-x-demo.sh`; `ffprobe docs/demo/media/studio-x-demo.mp4`.
3. **Then** — Post to X with script disclaimer (HTML mock); use `critique-studio-ux-from-capture` skill for next UX pass.
4. **Blocked on** — Native `li-studio` host window (PH-GD-5) for non-mock reel.

## Changed

- `scripts/record-studio-x-demo.sh` — default `origin/main`, refresh flag, playwright path
- `scripts/capture-studio-demo-png.mjs` — headless PNG helper
- `docs/demo/media/studio-x-demo.mp4`, `capture-provenance.json`
- `docs/demo/ux-critique-2026-05-25.md`, `studio-x-demo-script.md`, `RECORDING.md`

## Not changed

- `studio/src/**` compose/paint IR (no product UI behavior change)
- `lic` `deploy/studio-demo` HTML content (archived as-is from `98cdd7c`)
- `render` wgpu surface wiring
- Agent-kit / roadmap governance

## Breaking

N/A — demo assets only.

## Security

N/A — local ffmpeg/playwright; no trusted.lean or CVE surface.

## Performance

N/A — no bench threshold changes.

## Downstream

- **li-cursor-agents** — skills `record-studio-demo`, `critique-studio-ux-from-capture`, `align-studio-capture-with-vision` (separate PR).
