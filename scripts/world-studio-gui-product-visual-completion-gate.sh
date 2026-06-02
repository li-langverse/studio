#!/usr/bin/env bash
# Completion gate for world-studio-gui-product-visual.
#
# Delegates to gui-polish completion and syncs state artifacts.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"

bash "$ROOT/scripts/world-studio-gui-polish-completion-gate.sh"

PV_DIR="$ROOT/data/world-studio-gui-product-visual-loop"
POLISH_DIR="$ROOT/data/world-studio-gui-polish-loop"
mkdir -p "$PV_DIR"
if [[ -f "$POLISH_DIR/latest-screenshots.json" ]]; then
  cp -f "$POLISH_DIR/latest-screenshots.json" "$PV_DIR/latest-screenshots.json"
fi
if [[ -f "$POLISH_DIR/latest-iteration-assessment.json" ]]; then
  cp -f "$POLISH_DIR/latest-iteration-assessment.json" "$PV_DIR/latest-iteration-assessment.json"
fi
