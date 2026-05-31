#!/usr/bin/env bash
# Integration smoke: lis mcp li-engine stdio initialize + tools/list (WP-AG-03).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PY="${ROOT}/scripts/lis-mcp-li-engine.py"
[[ -f "$PY" ]] || { echo "missing $PY" >&2; exit 1; }

send() {
  local body="$1"
  local len
  len="$(printf '%s' "$body" | wc -c | tr -d ' ')"
  printf 'Content-Length: %s\r\n\r\n%s' "$len" "$body"
}

init_req='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"smoke","version":"0"}}}'
list_req='{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'

out="$( { send "$init_req"; send "$list_req"; } | python3 "$PY" )"
echo "$out" | grep -q '"protocolVersion":"2024-11-05"' || {
  echo "studio-mcp-li-engine-smoke: initialize response missing protocolVersion" >&2
  exit 1
}
echo "$out" | grep -q '"world_scaffold"' || {
  echo "studio-mcp-li-engine-smoke: tools/list missing world_scaffold" >&2
  exit 1
}
echo "$out" | grep -q '"lic_build"' || {
  echo "studio-mcp-li-engine-smoke: tools/list missing lic_build" >&2
  exit 1
}
echo "studio-mcp-li-engine-smoke: ok"
