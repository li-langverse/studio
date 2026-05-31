#!/usr/bin/env bash
# Run World Studio master plan loop until all todos done; idle when complete.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOOP="$ROOT/scripts/world-studio-plan-loop.py"
IDLE_SEC="${WORLD_STUDIO_IDLE_SEC:-1800}"
LOCK="${WORLD_STUDIO_FLOCK:-/tmp/li-world-studio-plan-loop.lock}"

if [[ -f "$HOME/Documents/Cursor/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$HOME/Documents/Cursor/.env"
  set +a
fi

export LI_CURSOR_AGENTS_ROOT="${LI_CURSOR_AGENTS_ROOT:-$ROOT/../li-cursor-agents}"

exec 9>"$LOCK"
if command -v flock >/dev/null 2>&1; then
  if ! flock -n 9; then
    echo "world-studio: another loop holds $LOCK"
    exit 0
  fi
fi

while true; do
  if ! python3 "$LOOP" --once; then
    rc=$?
    if [[ "$rc" -eq 0 ]]; then
      echo "world-studio: plan complete or idle ${IDLE_SEC}s"
      sleep "$IDLE_SEC"
      continue
    fi
    echo "world-studio: loop exit $rc — sleep 300s"
    sleep 300
    continue
  fi
  sleep 5
done
