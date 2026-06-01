#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${OUT:-$DIR/png}"
CHROME="${CHROME:-}"
for c in google-chrome chromium chromium-browser; do command -v "$c" >/dev/null 2>&1 && CHROME="$c" && break; done
[[ -n "$CHROME" ]] || { echo "no chrome"; exit 0; }
mkdir -p "$OUT"
capture_one(){ timeout "${CAPTURE_CHROME_TIMEOUT_SEC:-30}" "$CHROME" --headless --disable-gpu --hide-scrollbars --window-size=1920,1080 --screenshot="$2" "$1" && echo "  $2"; }
capture_motion(){ local f="$1" b="$2"; [[ "${STUDIO_UI_UX_CAPTURE_MOTION_FRAMES:-1}" == "0" ]] && return; grep -q data-reel-motion "$f" || return; for i in 0 1 2; do capture_one "file://${f}?reel_frame=$i" "$OUT/${b}-motion-${i}.png" || true; done; }
for f in "$DIR"/[0-9]*.html; do [[ -f "$f" ]] || continue; b=$(basename "$f" .html); capture_one "file://$f" "$OUT/${b}.png" || continue; capture_motion "$f" "$b"; done
