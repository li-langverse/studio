# Changelog

## [Unreleased]

Synced from lic `main` @ `7c0c37370259ddc2be0b9d720ac0dfb44c3a738e` (vertical sim-step hooks, MCP extended, `examples/verticals/`, `lig` deps).

### Added

- **`examples/verticals/**`** — seven World Studio profile TOMLs (`game`, `sim_*`) from lic monorepo.
- **Smokes** — `studio_agent_invoke.li`, `studio_mcp_extended.li`, `studio_sim_step_by_profile.li`, `studio_vertical_demo_env.li`; manifest parity with lic `packages/li-studio`.
- **`li.toml` deps** — `lig`, `li-scene`, `li-physics-runtime`, `li-ml-rl`, `li-sim-scientific`, `li-sim-automotive` (monorepo path pins; org consumers use published siblings).

### Changed

- **`src/lib.li`**, **`src/main.li`**, **`README.md`** — UX-11/12 agent invoke + error recovery; native-present demo env; **`import lig`** / `lig.present` (no `li-gpu`).

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
