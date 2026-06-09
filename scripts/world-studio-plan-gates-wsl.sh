#!/usr/bin/env bash
# Run world-studio gates on Linux via WSL Ubuntu (when available).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GATES="$ROOT/scripts/world-studio-plan-gates.sh"
WSL_DISTRO="${WORLD_STUDIO_WSL_DISTRO:-Ubuntu-24.04}"

run_gates() {
  export LI_REPO_ROOT="$ROOT"
  export WORLD_STUDIO_GATES_SKIP_LIC="${WORLD_STUDIO_GATES_SKIP_LIC:-0}"
  bash "$GATES"
}

if [[ "$(uname -s)" == "Linux" ]]; then
  run_gates
  exit $?
fi

if ! command -v wsl >/dev/null 2>&1; then
  echo "world-studio-plan-gates-wsl: no WSL — running Windows gates only" >&2
  run_gates
  exit $?
fi

WIN_ROOT="$(cd "$ROOT" && pwd -W 2>/dev/null | tr '\\' '/' || echo "$ROOT" | sed 's|\\|/|g')"
WSL_ROOT="$(echo "$WIN_ROOT" | sed 's|^\([A-Za-z]\):|/mnt/\L\1|')"

echo "world-studio-plan-gates-wsl: Linux gates via WSL ($WSL_DISTRO) at $WSL_ROOT"
wsl -d "$WSL_DISTRO" -e bash -lc "
  set -euo pipefail
  cd '$WSL_ROOT'
  for f in scripts/world-studio-plan-gates.sh scripts/lib/li-ui.sh scripts/bench-studio-viewport-perf.sh; do
    [[ -f \"\$f\" ]] && sed -i 's/\\r$//' \"\$f\"
  done
  export LI_REPO_ROOT='$WSL_ROOT'
  export WORLD_STUDIO_GATES_SKIP_LIC='${WORLD_STUDIO_GATES_SKIP_LIC:-0}'
  if [[ -d /usr/lib/llvm-22/lib/cmake/llvm ]]; then
    export LLVM_DIR=/usr/lib/llvm-22/lib/cmake/llvm
    export CC=clang-22 CXX=clang++-22
  fi
  bash ./scripts/world-studio-plan-gates.sh
"