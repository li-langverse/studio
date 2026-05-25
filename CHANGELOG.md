# Changelog

## [Unreleased]

Synced from lic `feat/ph-hw-multi-vendor` @ `6ca38be9b2b236eb92f7e3b54f61d39d0abf7675` (org studio parity PR).

### Added

- **`li-studio-demo` binary** — `[[bin]]` in `li.toml`, `src/main.li`, `examples/studio_shell_demo.toml`.
- **`li-sim` dependency** — profile/scene stubs aligned with lic monorepo package graph.
- **README** — PH-HW syntax line: viewport host uses **`import lig`** (replaces `import gpu`).

### Changed

- **Manifest** — parity with lic `packages/li-studio/li-tests/manifest.toml` (12 smokes).
- **src/lib.li**, smokes, fixtures, bench — byte-match lic `packages/li-studio` at sync SHA.
