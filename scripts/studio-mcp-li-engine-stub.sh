#!/usr/bin/env bash
# WP-AG-03: minimal MCP stdio stub for Studio tool names (lis mcp li-engine placeholder).
# Reads newline-delimited JSON-RPC 2.0 requests on stdin; writes responses on stdout.
# Product logic remains in Li (studio_mcp_tool_dispatch); this is transport scaffolding only.
set -euo pipefail

TOOL_NAMES='world_scaffold sim_set_profile lic_check lic_build publish_bundle am_export_print chem_dft_run studio_adaptive_layout set_viewport_background set_particle_display set_biomol_style'

respond() {
  printf '%s\n' "$1"
}

while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "$line" ]] && continue
  method=$(printf '%s' "$line" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("method",""))' 2>/dev/null || echo "")
  id=$(printf '%s' "$line" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("id","null"))' 2>/dev/null || echo "null")
  case "$method" in
    initialize)
      respond "{\"jsonrpc\":\"2.0\",\"id\":$id,\"result\":{\"protocolVersion\":\"2024-11-05\",\"capabilities\":{\"tools\":{}},\"serverInfo\":{\"name\":\"li-engine-stub\",\"version\":\"0.1.0\"}}}"
      ;;
    tools/list)
      tools_json=$(python3 - <<'PY'
import json
names = """world_scaffold sim_set_profile lic_check lic_build publish_bundle am_export_print chem_dft_run studio_adaptive_layout set_viewport_background set_particle_display set_biomol_style""".split()
print(json.dumps([{"name": n, "description": f"Li Studio tool {n} (stub transport)"} for n in names]))
PY
)
      respond "{\"jsonrpc\":\"2.0\",\"id\":$id,\"result\":{\"tools\":$tools_json}}"
      ;;
    tools/call)
      name=$(printf '%s' "$line" | python3 -c 'import json,sys; r=json.load(sys.stdin); print(r.get("params",{}).get("name",""))' 2>/dev/null || echo "")
      respond "{\"jsonrpc\":\"2.0\",\"id\":$id,\"result\":{\"content\":[{\"type\":\"text\",\"text\":\"stub ok: $name — use in-process studio_mcp_tool_dispatch in Li\"}],\"isError\":false}}"
      ;;
    *)
      respond "{\"jsonrpc\":\"2.0\",\"id\":$id,\"error\":{\"code\":-32601,\"message\":\"method not found\"}}"
      ;;
  esac
done
