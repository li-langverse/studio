---
name: World Studio master plan loop
overview: Plan-loop checklist for shipping the native Li World Studio master plan. This file is the canonical gate input for `./scripts/world-studio-plan-*-gate*.sh`.
todos:
  - id: wsm-w0-docs-hub
    content: "W0 — Docs hub + master plan wiring"
    status: done
  - id: wsm-w0-gd1-shell
    content: "W0 — GD1 shell: native regions + chrome scaffold"
    status: done
  - id: wsm-w0-sim-bridge
    content: "W0 — Sim bridge stub (profile → sim runner wiring)"
    status: done
  - id: wsm-w0-agent-registry
    content: "W0 — Agent registry + minimal dispatch plumbing"
    status: done
  - id: wsm-w0-profile-chips
    content: "W0 — Profile chips + shell navigation"
    status: done

  - id: wsm-w1-profile-smokes
    content: "W1 — Profile smokes in li-tests (proof gates)"
    status: done
  - id: wsm-w1-sim3-envpool
    content: "W1 — SIM env pool (SIM-03)"
    status: done
  - id: wsm-w1-sim-sensors
    content: "W1 — SIM sensors + observation plumbing"
    status: done
  - id: wsm-w1-studio-toml-engine
    content: "W1 — Studio TOML engine config plumbing"
    status: done
  - id: wsm-w1-timeline-playback
    content: "W1 — Timeline playback controls"
    status: done
  - id: wsm-w1-command-palette
    content: "W1 — Command palette"
    status: done
  - id: wsm-w1-keyboard-bridge
    content: "W1 — Keyboard bridge (native input → widget events)"
    status: done
  - id: wsm-w1-agent-chrome-fsm
    content: "W1 — Agent chrome FSM + task state surfacing"
    status: done

  - id: wsm-w2-wgpu-viewport
    content: "W2 — WGPU viewport path (WP-GD-05)"
    status: done
  - id: wsm-w2-viewport-hud
    content: "W2 — Viewport HUD overlays"
    status: done
  - id: wsm-w2-viewport-error
    content: "W2 — Viewport error UX (strip + retry)"
    status: done
  - id: wsm-w2-native-pixels
    content: "W2 — Native pixels truth (present path is Li raster)"
    status: done
  - id: wsm-w2-c-host-retire
    content: "W2 — Retire C paint_fb mirror in host"
    status: done

  - id: wsm-w3-mcp-dispatch
    content: "W3 — MCP tool dispatch layer (studio_mcp_tool_*)"
    status: done
  - id: wsm-w3-mcp-server
    content: "W3 — MCP server wiring (WP-AG-03)"
    status: done
  - id: wsm-w3-apply-patch-loop
    content: "W3 — Apply/undo patch loop (agent iteration support)"
    status: done
  - id: wsm-w3-interaction-modes
    content: "W3 — Interaction modes UX requirements (UX-06)"
    status: done

  - id: wsm-w4-world-checkpoint
    content: "W4 — World checkpoint save/load skeleton"
    status: done
  - id: wsm-w4-world-io
    content: "W4 — World I/O bundle format + roundtrip"
    status: done
  - id: wsm-w4-gltf-ingest
    content: "W4 — GLTF ingest into world assets"
    status: done

  - id: wsm-w5-sci-kernels
    content: "W5 — Sci kernels hooks + integration points"
    status: done
  - id: wsm-w5-sim-viz
    content: "W5 — SIM visualization stub (native viewport)"
    status: done
  - id: wsm-w5-robo-ik
    content: "W5 — Robo IK vertical stub"
    status: done
  - id: wsm-w5-am-export
    content: "W5 — AM export vertical stub"
    status: done
  - id: wsm-w5-drug-adaptive
    content: "W5 — Drug adaptive vertical stub"
    status: done

  - id: wsm-w6-publish-figures
    content: "W6 — Publish figures export path"
    status: done
  - id: wsm-w6-publish-data
    content: "W6 — Publish data export path"
    status: done
  - id: wsm-w6-repro-bundle
    content: "W6 — Repro bundle build"
    status: done
  - id: wsm-w6-player-ship
    content: "W6 — Player ship path"
    status: done
  - id: wsm-w6-agent-eval
    content: "W6 — Agent eval harness"
    status: done
  - id: wsm-w6-vertical-dod
    content: "W6 — Vertical definition-of-done gate"
    status: done
isProject: false
---

# World Studio master plan loop

This plan-loop file is consumed by:

- `./scripts/world-studio-plan-gates.sh`
- `./scripts/world-studio-plan-completion-gate.sh`

All `wsm-w*` items are marked **done** based on `data/world-studio-plan-loop/state.json`.
Canonical plan hub: [WORLD-STUDIO-MASTER-PLAN.md](../../game-dev/WORLD-STUDIO-MASTER-PLAN.md)

