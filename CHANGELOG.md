# Changelog

## [Unreleased]

### Changed

- **X demo reel (Wave 2, studio-ux-19)** — Motion workspace frames + five-scene `studio-x-demo.mp4` (~37.5s); `capture-provenance.json` `motion_frames: true`; `scripts/record-studio-x-demo.sh` / `capture-studio-demo-png.mjs`; native capture skeleton in `RECORDING.md`.
- **X demo reel** — Regenerated `docs/demo/media/studio-x-demo.mp4` from `lic` `deploy/studio-demo`; PNG capture; `capture-provenance.json` with `wave: 2`.

Synced from lic `main` @ `3984cbf3820ee508e4eae90a6162aa0abd2093c8` (PH-HW #224 merged; lig present + vertical demos).

### Added

- **`li-studio-demo` binary** — `[[bin]]` in `li.toml`, `src/main.li`, `examples/studio_shell_demo.toml`.
- **`li-sim` dependency** — profile/scene stubs aligned with lic monorepo package graph.
- **README** — PH-HW syntax line: viewport host uses **`import lig`** (replaces `import gpu`).

### Changed

- **Manifest** — parity with lic `packages/li-studio/li-tests/manifest.toml` (12 smokes).
- **src/lib.li**, smokes, fixtures, bench — byte-match lic `packages/li-studio` at sync SHA.
