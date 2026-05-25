#!/usr/bin/env bash
# Build Li World Studio X demo MP4 from lic deploy/studio-demo HTML mocks.
# Full chrome is not yet capturable from native li-studio (headless compose only; wgpu surface_ok=false).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIC_ROOT="${LIC_ROOT:-$ROOT/../lic}"
LIC_BRANCH="${LIC_STUDIO_BRANCH:-origin/main}"
CACHE="${STUDIO_DEMO_CACHE:-$ROOT/.demo-cache}"
DEMO="$CACHE/deploy/studio-demo"
SHOTS="$DEMO/screenshots"
PNG="$SHOTS/png"
MEDIA="$ROOT/docs/demo/media"
PROV="$MEDIA/capture-provenance.json"
CHROME="${CHROME:-}"

for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome chromium chromium-browser; do
  if [[ -x "$c" ]] || command -v "$c" >/dev/null 2>&1; then
    CHROME="$c"
    break
  fi
done

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "record-studio-x-demo: install ffmpeg (e.g. brew install ffmpeg)" >&2
  exit 2
fi

mkdir -p "$CACHE" "$MEDIA" "$PNG"

need_extract=0
if [[ "${STUDIO_DEMO_REFRESH:-0}" == "1" ]]; then
  need_extract=1
elif [[ ! -f "$SHOTS/01-studio-workspace.html" ]]; then
  need_extract=1
fi

if [[ "$need_extract" == "1" ]]; then
  if [[ ! -d "$LIC_ROOT/.git" ]]; then
    echo "record-studio-x-demo: LIC_ROOT=$LIC_ROOT not a git repo" >&2
    exit 3
  fi
  ref="${LIC_BRANCH#origin/}"
  echo "record-studio-x-demo: archive deploy/studio-demo from lic ($LIC_BRANCH)"
  git -C "$LIC_ROOT" fetch origin "$ref" 2>/dev/null || true
  rm -rf "$CACHE/deploy"
  git -C "$LIC_ROOT" archive "$LIC_BRANCH" deploy/studio-demo | tar -x -C "$CACHE"
fi

if [[ -z "$CHROME" ]]; then
  echo "record-studio-x-demo: Chrome/Chromium required for PNG capture" >&2
  exit 4
fi

lic_sha="$(git -C "$LIC_ROOT" rev-parse "$LIC_BRANCH" 2>/dev/null || echo unknown)"
studio_sha="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"

capture_pngs() {
  echo "record-studio-x-demo: PNG capture (1920x1080)"
  mkdir -p "$PNG"
  if [[ "${STUDIO_CAPTURE_USE_PLAYWRIGHT:-1}" == "1" ]] && command -v node >/dev/null 2>&1; then
    if [[ -f "$ROOT/scripts/capture-studio-demo-png.mjs" ]]; then
      echo "record-studio-x-demo: playwright (Chrome --screenshot often hangs on macOS)"
      node "$ROOT/scripts/capture-studio-demo-png.mjs" "$SHOTS"
      return 0
    fi
  fi
  capture_motion_chrome() {
    local f="$1" base="$2"
    [[ "${STUDIO_CAPTURE_MOTION_FRAMES:-1}" == "0" ]] && return 0
    grep -q data-reel-motion "$f" || return 0
    local i url
    for i in 0 1 2; do
      url="file://${f}?reel_frame=${i}"
      timeout "${STUDIO_CAPTURE_TIMEOUT_SEC:-25}" \
        "$CHROME" --headless --disable-gpu --hide-scrollbars \
        --window-size=1920,1080 \
        --screenshot="$PNG/${base}-motion-${i}.png" \
        "$url" || return 1
      echo "  $PNG/${base}-motion-${i}.png"
    done
  }
  for f in "$SHOTS"/[0-9]*.html; do
    [[ -f "$f" ]] || continue
    base=$(basename "$f" .html)
    timeout "${STUDIO_CAPTURE_TIMEOUT_SEC:-25}" \
      "$CHROME" --headless --disable-gpu --hide-scrollbars \
      --window-size=1920,1080 \
      --screenshot="$PNG/${base}.png" \
      "file://${f}" || {
      echo "record-studio-x-demo: failed $base" >&2
      exit 5
    }
    echo "  $PNG/${base}.png"
    capture_motion_chrome "$f" "$base" || true
  done
}
capture_pngs

LIST="$MEDIA/ffmpeg-scenes.txt"
scene_line() { printf "file '%s'\nduration %s\n" "$1" "$2" >>"$LIST"; }

# Wave 2 reel: workspace motion (3×2.5s) → invoke → palette → error → CTA hold
: >"$LIST"
if [[ -f "$PNG/01-studio-workspace-motion-0.png" ]]; then
  scene_line "$PNG/01-studio-workspace-motion-0.png" 2.5
  scene_line "$PNG/01-studio-workspace-motion-1.png" 2.5
  scene_line "$PNG/01-studio-workspace-motion-2.png" 2.5
else
  scene_line "$PNG/01-studio-workspace.png" 8
fi
scene_line "$PNG/02-studio-empty-viewport.png" 6
scene_line "$PNG/04-studio-command-palette.png" 5
scene_line "$PNG/03-studio-agent-error.png" 7
scene_line "$PNG/05-studio-end-cta.png" 6
scene_line "$PNG/05-studio-end-cta.png" 0.5

REEL_SCENES='["01-studio-workspace-motion-0","01-studio-workspace-motion-1","01-studio-workspace-motion-2","02-studio-empty-viewport","04-studio-command-palette","03-studio-agent-error","05-studio-end-cta"]'
if [[ ! -f "$PNG/01-studio-workspace-motion-0.png" ]]; then
  REEL_SCENES='["01-studio-workspace","02-studio-empty-viewport","04-studio-command-palette","03-studio-agent-error","05-studio-end-cta"]'
fi

echo "record-studio-x-demo: encoding MP4 (Wave 2 beats + motion)"
ffmpeg -y -f concat -safe 0 -i "$LIST" \
  -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" \
  -c:v libx264 -pix_fmt yuv420p -r 30 \
  "$MEDIA/studio-x-demo.mp4" 2>/dev/null

cat >"$PROV" <<EOF
{
  "captured_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "capture_mode": "html_mock_playwright_chrome",
  "lic_root": "$LIC_ROOT",
  "lic_ref": "$LIC_BRANCH",
  "lic_sha": "$lic_sha",
  "studio_sha": "$studio_sha",
  "chrome": "$CHROME",
  "scenes": ${REEL_SCENES},
  "motion_frames": $([ -f "$PNG/01-studio-workspace-motion-0.png" ] && echo true || echo false),
  "native_window": false,
  "notes": "Marketing mocks with mock-banner; not li-studio-demo/wgpu shell. Motion via reel_frame query when data-reel-motion present."
}
EOF

echo "record-studio-x-demo: done → $MEDIA/studio-x-demo.mp4"
ffprobe -v quiet -show_entries format=duration,size -of default=noprint_wrappers=1 "$MEDIA/studio-x-demo.mp4" 2>/dev/null || true
echo "Provenance → $PROV"
echo "Voiceover / post copy → docs/demo/studio-x-demo-script.md"

if [[ "${STUDIO_CAPTURE_TRY_NATIVE:-0}" == "1" ]]; then
  export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-/opt/homebrew/lib/pkgconfig}"
  if [[ -f "$DEMO/native/capture.sh" ]]; then
    echo "record-studio-x-demo: optional native SDL (needs DISPLAY / macOS window server)"
    STUDIO_VIEWPORT_CAPTURE_OUT="$DEMO/native/out" bash "$DEMO/native/capture.sh" || true
  fi
fi
