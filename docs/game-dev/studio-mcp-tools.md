# Studio MCP tools (PH-AGENT contract)

**Status:** AGENT-1 in-process dispatch **done**; WP-AG-03 stdio server wired (transport + native handlers)  
**Vision:** [world-studio-vision.md](world-studio-vision.md) §18  
**RFC:** [specs/studio-cursor-sdk-rfc.md](specs/studio-cursor-sdk-rfc.md)

Li World Studio agents call these tools via MCP (`lis mcp li-engine`) — stdio transport in `scripts/lis-mcp-li-engine.py` (Cursor config) delegates to native `studio_mcp_server_*` handlers and `studio_mcp_tool_dispatch_arg`.

## Proof gate

Any tool that mutates project state or ships artifacts must run **`lic build`** (and typically `lic check --format=json` first). Agent chrome surfaces `studio_mcp_lic_build` as the proof gate tool; failed proof maps to `studio_mcp_tool_result_err_proof`.

## Tool table

| ID constant | MCP name | Conceptual args | Action |
|-------------|----------|-----------------|--------|
| `studio_mcp_world_scaffold` | `world_scaffold` | `template_id: str`, `target_dir: str` | Create `world.li` + `assets/` + `studio.toml` from spin-up template |
| `studio_mcp_sim_set_profile` | `sim_set_profile` | `profile: str` (e.g. `sim_additive`) | Set `[engine] profile` in `studio.toml` |
| `studio_mcp_lic_check` | `lic_check` | `paths: str[]` (optional) | Run `lic check --format=json`; return diagnostics |
| `studio_mcp_lic_build` | `lic_build` | `target: str` (optional triple) | Run `lic build`; **required** before publish/export |
| `studio_mcp_publish_bundle` | `publish_bundle` | `out_path: str` | Write repro bundle (SVG/HDF5/manifest) after proof pass |
| `studio_mcp_am_export_print` | `am_export_print` | `format` arg (`am_export_format_*`) | `sim_export_print` after slicer workflow (3MF/G-code magic tags) |
| `studio_mcp_chem_dft_run` | `chem_dft_run` | `input_path: str`, `method: str` (optional) | Queue QM/DFT job via `li-chem` (stub) |
| `studio_mcp_studio_adaptive_layout` | `studio_adaptive_layout` | `role: str`, `stage: str` | Drug/role adaptive shell layout (`layout_studio_shell_adaptive`) |
| `studio_mcp_set_viewport_background` | `studio_set_viewport_background` | `bg: int` (0 solid, 1 grid, 2 gradient) | Sets runtime viewport background preset (CPU paint_blit) |
| `studio_mcp_set_particle_display` | `studio_set_particle_display` | `tier_id: int` (-1 off, 0–2 = 1k/10k/100k) | MD particle tier label + placeholder dots in viewport |
| `studio_mcp_set_biomol_style` | `studio_set_biomol_style` | `style: int` (0 cartoon, 1 surface, 2 sticks) | Biomolecule representation chip color (stub, not mesh) |

| `studio_mcp_server_handle_method(state, method, tool_name, arg)` | WP-AG-03 JSON-RPC method dispatch (initialize / tools/list / tools/call / ping) |
| `studio_mcp_server_handle_tools_call(state, tool_name, arg)` | MCP tools/call → `studio_mcp_tool_dispatch_arg` |
| `studio_ai_mcp_dispatch(tool_name, arg_count)` | `li-studio-ai` in-process bridge to dispatch |

## Stdio server (WP-AG-03)

| Entry | Role |
|-------|------|
| `scripts/lis-mcp-li-engine.sh` | Cursor MCP stdio command (`lis mcp li-engine` delegate) |
| `scripts/lis-mcp-li-engine.py` | MCP JSON-RPC transport; 11-tool allowlist |
| `scripts/studio-mcp-li-engine-smoke.sh` | initialize + tools/list integration smoke |

Cursor MCP config example:

```json
{
  "mcpServers": {
    "li-engine": {
      "command": "bash",
      "args": ["<lic>/scripts/lis-mcp-li-engine.sh"]
    }
  }
}
```

## Runtime API (`import studio`)

| Symbol | Role |
|--------|------|
| `studio_mcp_tool_count()` | Returns `11` |
| `studio_mcp_tool_dispatch_arg(tool_id, arg)` | All 11 tools apply normalized `arg` (profile, proof gate, export mask, viewport, LITL stage) |
| `studio_mcp_tool_dispatch(tool_id)` | Default arg `0`; invalid ID → `status_failed` + `result_err_io` |
| `studio_mcp_tool_name(id)` | Round-trip name via `li_rt` const table |
| `studio_mcp_tool_from_name(name)` | Parse MCP tool name → ID |
| `studio_mcp_tool_id_valid(id)` | Non-zero IDs only |
| `StudioAgentToolRequest` | `tool_id`, `status`, `result_code` on agent chrome |
| `studio_compose_agent_chrome_with_tool` | Optional tool request on compose |

## Status / result codes (stub)

| Status | Constant |
|--------|----------|
| idle | `studio_mcp_tool_status_idle` |
| pending | `studio_mcp_tool_status_pending` |
| ok | `studio_mcp_tool_status_ok` |
| failed | `studio_mcp_tool_status_failed` |

| Result | Constant |
|--------|----------|
| ok | `studio_mcp_tool_result_ok` |
| proof failure | `studio_mcp_tool_result_err_proof` |
| I/O | `studio_mcp_tool_result_err_io` |

## Smoke

- `li-tests/smoke/studio_mcp_tools.li` — wave-1 ID/name round-trip and agent chrome optional field.
- `li-tests/smoke/studio_mcp_extended.li` — gap #6/#7 tool IDs, `studio_mcp_tool_dispatch`, adaptive layout hook.
- `li-tests/smoke/studio_mcp_stdio_server.li` — WP-AG-03 native server handlers + tools/call dispatch.
- `scripts/studio-mcp-li-engine-smoke.sh` — stdio initialize + tools/list integration.
- `packages/li-studio-ai/li-tests/smoke/studio_ai_mcp_dispatch.li` — `studio_ai_mcp_dispatch` wired to dispatch.
- `li-tests/smoke/studio_viewport_display.li` — viewport background / particle tier / biomol style MCP + compose/paint.
- `li-tests/composable/import_lig_chem_backend.li` — `chem_dft_run_smoke()` stub energy (`-76.0` Hartree); `chem_lig_backend_auto` unchanged.

## Not in this slice

- `@cursor/sdk` cloud session wiring (local `studio_ai_complete` uses `llm_generate` when fixture weights load)
- Live `chem_dft_run` queue and full printer send (OctoPrint/Bambu) — `am_export_print` runs `sim_export_print` contract only

## apply_patch loop (WP-AG-04)

| Symbol | Role |
|--------|------|
| `studio_ai_apply_patch(patch, target_file)` | Apply patch marker → `studio_mcp_lic_check` dispatch (JSON gate mock) |
| `studio_ai_apply_patch_loop(patch, target_file, max_retries)` | Retry until green or exhausted |
| `studio_ai_complete(prompt)` | `llm_generate` when fixture weights load; else honest empty |
| Patch markers | `@@valid@@`, `@@fail@@`, `@@retry@@` (smoke/eval contract) |

Smoke: `packages/li-studio-ai/li-tests/smoke/studio_ai_apply_patch_loop.li`
