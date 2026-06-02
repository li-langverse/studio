---
name: World Studio master plan loop
overview: Goal-directed execution loop for WORLD-STUDIO-MASTER-PLAN.md (wsm-w0…w6).
todos:
  - id: wsm-w0-docs-hub
    content: "W0 — Docs hub + navigation index present"
    status: done
  - id: wsm-w0-gd1-shell
    content: "W0 — GD-1 shell scaffold (compose/paint IR) wired"
    status: done
  - id: wsm-w0-sim-bridge
    content: "W0 — Unified sim bridge hook exists for all profiles"
    status: done
  - id: wsm-w0-agent-registry
    content: "W0 — Agent MCP registry and in-process dispatch baseline"
    status: done
  - id: wsm-w0-profile-chips
    content: "W0 — Profile chips / vertical registry visible in shell"
    status: done
  - id: wsm-w1-profile-smokes
    content: "W1 — All profile smokes green"
    status: done
  - id: wsm-w1-sim3-envpool
    content: "W1 — SIM-3 env pool hooks / stubs landed"
    status: done
  - id: wsm-w1-sim-sensors
    content: "W1 — Sim sensor hooks wired (auto/robo/sci stubs)"
    status: done
  - id: wsm-w1-studio-toml-engine
    content: "W1 — studio.toml [engine] profile roundtrip"
    status: done
  - id: wsm-w1-timeline-playback
    content: "W1 — Timeline play/pause + playhead display wired"
    status: done
  - id: wsm-w1-command-palette
    content: "W1 — Command palette (Ctrl/Cmd+K) functional"
    status: done
  - id: wsm-w1-keyboard-bridge
    content: "W1 — Keyboard bridge routes host keys into studio"
    status: done
  - id: wsm-w1-agent-chrome-fsm
    content: "W1 — Agent chrome FSM: idle/running/blocked/failed/done"
    status: done
  - id: wsm-w2-wgpu-viewport
    content: "W2 — wgpu viewport path present (readback/probes)"
    status: done
  - id: wsm-w2-viewport-hud
    content: "W2 — Viewport HUD overlays readable (mode/selection/FPS)"
    status: done
  - id: wsm-w2-viewport-error
    content: "W2 — Viewport error overlay + retry strip"
    status: done
  - id: wsm-w2-native-pixels
    content: "W2 — native_pixels honesty integrated (UX-14)"
    status: done
  - id: wsm-w2-c-host-retire
    content: "W2 — C host retirement: I/O only; no paint mirror"
    status: done
  - id: wsm-w3-mcp-dispatch
    content: "W3 — MCP dispatch: tool registry + allowlist"
    status: done
  - id: wsm-w3-mcp-server
    content: "W3 — MCP stdio server path (WP-AG-03) present"
    status: done
  - id: wsm-w3-apply-patch-loop
    content: "W3 — apply_patch → lic check loop (WP-AG-04) scaffold"
    status: done
  - id: wsm-w3-interaction-modes
    content: "W3 — Interaction modes FSM (WP-UX-15) stubbed/linked"
    status: done
  - id: wsm-w4-world-checkpoint
    content: "W4 — World checkpoint snapshot contract present"
    status: done
  - id: wsm-w4-world-io
    content: "W4 — world.li I/O roundtrip stub"
    status: done
  - id: wsm-w4-gltf-ingest
    content: "W4 — glTF ingest placeholder path registered"
    status: done
  - id: wsm-w5-sci-kernels
    content: "W5 — Scientific kernel stubs and perf tiers registry"
    status: done
  - id: wsm-w5-sim-viz
    content: "W5 — sim.viz panel scaffolding"
    status: done
  - id: wsm-w5-robo-ik
    content: "W5 — Robotics IK pilot stub"
    status: done
  - id: wsm-w5-am-export
    content: "W5 — AM export tool stub (3MF/G-code placeholder)"
    status: done
  - id: wsm-w5-drug-adaptive
    content: "W5 — Drug adaptive inspector/layout pilot"
    status: done
  - id: wsm-w6-publish-figures
    content: "W6 — Publish figures export path stub"
    status: done
  - id: wsm-w6-publish-data
    content: "W6 — Publish data export path stub"
    status: done
  - id: wsm-w6-repro-bundle
    content: "W6 — Repro bundle contract and manifest"
    status: done
  - id: wsm-w6-player-ship
    content: "W6 — li-player ship path placeholder"
    status: done
  - id: wsm-w6-agent-eval
    content: "W6 — Agent eval harness gate (WP-AG-06) present"
    status: done
  - id: wsm-w6-vertical-dod
    content: "W6 — Vertical Definition-of-Done gate present"
    status: done
isProject: false
---

# World Studio master plan loop

This YAML is consumed by `./scripts/world-studio-plan-loop.py` and gated by `./scripts/world-studio-plan-gates.sh`.

