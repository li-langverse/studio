# Studio X demo Wave 2 refresh (studio-ux-19)

## Summary

Regenerated the marketing reel from lic Wave 2 HTML mocks with workspace motion frames (3×2.5s) plus palette/error/CTA scenes (~37.5s).

## Agent continuation

1. Read `docs/demo/capture-provenance.json` and `lic/docs/superpowers/plans/2026-05-24-studio-ui-ux-plan-loop.md` (studio-ux-19 → done after merge).
2. Run `STUDIO_DEMO_REFRESH=1 ./scripts/record-studio-x-demo.sh` after lic Wave 2 HTML is on `origin/main`.
3. Next: wire native `li-studio` agent invoke (PH-AGENT) — mocks are not product UI.
4. Blocked on **PH-GD-5** for `native_window: true` provenance.

## Changed

- `docs/demo/media/studio-x-demo.mp4`, `capture-provenance.json`, `ffmpeg-scenes.txt`
- `scripts/record-studio-x-demo.sh`, `scripts/capture-studio-demo-png.mjs` — motion `reel_frame` PNGs; scenes `01-motion-*`, `02`, `04`, `03`, `05`
- `scripts/record-studio-x-demo-native.sh`, `docs/demo/RECORDING.md` — PH-GD-5 native blocker documented
- `docs/demo/studio-x-demo-script.md`, `docs/demo/ux-critique-2026-05-25.md` (Wave 2 section)
- Plan todo **studio-ux-19** evidence pack

## Not changed

- `li-studio-demo` / wgpu host — still headless; no native window capture.
- lic Wave 2 HTML source of truth until PR merges to `main` (recorder used worktree + commit `8acba3c9`).

## Breaking

N/A — marketing assets only.

## Security

N/A — static HTML mocks; no secrets in repo.

## Performance

N/A — no runtime bench change.

## Downstream

- **lic:** merge `feat/studio-ux-wave2-*` branches with `deploy/studio-demo/screenshots/` Wave 2 files.
- **X post:** attach MP4; label `capture_mode: html_mock_*` and mock banner in copy.
