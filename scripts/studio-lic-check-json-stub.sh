#!/usr/bin/env bash
# WP-AG-04: JSON diagnostics stub for `lic check --format=json` (transport only).
# Usage: studio-lic-check-json-stub.sh <path.li>
set -euo pipefail

target="${1:-}"
if [[ -z "$target" ]]; then
  printf '{"ok":false,"diagnostics":[{"severity":"error","message":"missing path"}]}\n'
  exit 1
fi
if [[ ! -f "$target" ]]; then
  printf '{"ok":false,"diagnostics":[{"severity":"error","message":"file not found","path":"%s"}]}\n' "$target"
  exit 2
fi
printf '{"ok":true,"diagnostics":[],"path":"%s"}\n' "$target"
exit 0
