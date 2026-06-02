#!/usr/bin/env bash
# Progress gates for world-studio-gui-product-visual.
#
# This loop is implemented by the completed GUI polish sprint; we delegate to the
# gui-polish gates and keep product-visual state files synced for workflow tools.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"

bash "$ROOT/scripts/world-studio-gui-polish-gates.sh"

# Sync polish loop artifacts into product-visual loop state dir.
PV_DIR="$ROOT/data/world-studio-gui-product-visual-loop"
POLISH_DIR="$ROOT/data/world-studio-gui-polish-loop"
mkdir -p "$PV_DIR"
if [[ -f "$POLISH_DIR/latest-screenshots.json" ]]; then
  cp -f "$POLISH_DIR/latest-screenshots.json" "$PV_DIR/latest-screenshots.json"
fi
if [[ -f "$POLISH_DIR/latest-iteration-assessment.json" ]]; then
  cp -f "$POLISH_DIR/latest-iteration-assessment.json" "$PV_DIR/latest-iteration-assessment.json"
fi
