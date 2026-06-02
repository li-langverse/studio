# World Studio GUI polish W5 — screenshot gate

**Plan:** [2026-05-31-world-studio-gui-polish-loop.md](../superpowers/plans/2026-05-31-world-studio-gui-polish-loop.md)  
**Branch:** `cursor/world-studio-gui-polish`

## Delivered

- Native `polish-game.png`, `polish-game-1280x720.png`, `polish-sim_rl.png`, `polish-sim_drug_design.png` under `docs/demo/media/native-verticals/png/`.
- `paint_blit` framebuffer mirrors W4 polish: panel shadows, glyph bars, profile viewport previews (game blocks, sim particles, drug sticks), HUD legend.
- `world-studio-gui-polish-gates.sh` captures via `studio_verticals_present_host` (not SDL-only solid fill).
- Completion gate PNG heuristic decodes RGB rows with filter bytes (230+ colors vs false wireframe fail).

## Gates

```bash
./scripts/world-studio-gui-polish-gates.sh
./scripts/world-studio-gui-polish-completion-gate.sh  # exit 0
```

**native_only:** true — HTML mocks are not completion proof.
