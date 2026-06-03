#!/usr/bin/env bash
# MCP li-engine smoke — tools/list includes ui_snapshot.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIC_ROOT="${LIC_ROOT:-$ROOT/../lic}"
PY="$LIC_ROOT/scripts/lis-mcp-li-engine.py"
[[ -f "$PY" ]] || PY="$ROOT/../lic/scripts/lis-mcp-li-engine.py"
[[ -f "$PY" ]] || { echo "studio-mcp-li-engine-smoke: missing lis-mcp-li-engine.py" >&2; exit 1; }
python3 - "$PY" <<'PY'
import json, subprocess, sys
py = sys.argv[1]
proc = subprocess.run(["python3", py], input=json.dumps({"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}})+"\n", capture_output=True, text=True)
line = proc.stdout.strip().splitlines()[-1]
resp = json.loads(line)
tools = [t["name"] for t in resp.get("result", {}).get("tools", [])]
need = {"ui_snapshot", "ui_click", "demo_record_finish"}
missing = need - set(tools)
if missing:
    print("studio-mcp-li-engine-smoke: missing tools:", ", ".join(sorted(missing)), file=sys.stderr)
    sys.exit(1)
print("studio-mcp-li-engine-smoke: OK")
PY
