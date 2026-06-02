#!/usr/bin/env bash
# Capture one native PNG per World Studio vertical.
# Product-truth default: SDL host presents pixels produced by Li rasterizer (no C paint_fb mirror).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NATIVE="$ROOT/deploy/studio-demo/native"
BIN="${STUDIO_VERTICALS_PRESENT_HOST_BIN:-$NATIVE/studio_shell_present_host}"
PNG_DIR="${STUDIO_VERTICALS_NATIVE_PNG_DIR:-$ROOT/docs/demo/media/native-verticals/png}"
META="${STUDIO_VERTICALS_NATIVE_META:-$ROOT/docs/demo/media/native-verticals/capture.json}"
WIDTH="${STUDIO_VERTICALS_CAPTURE_WIDTH:-1920}"
HEIGHT="${STUDIO_VERTICALS_CAPTURE_HEIGHT:-1080}"
export LIG_HOST_PRESENT="${LIG_HOST_PRESENT:-1}"
if [[ "${STUDIO_VERTICALS_WGPU_READBACK:-0}" == "1" ]]; then
  export LIG_WGPU_READBACK=1
fi

# slug:profile_id — sim_drug_design (7) uses Li studio_compose_shell_drug_litl (frame_id = LITL tick).
VERTICALS=(
  "game:1"
  "sim_rl:2"
  "sim_automotive:3"
  "sim_robotics:4"
  "sim_additive:5"
  "sim_scientific:6"
  "sim_drug_design:7"
)

mkdir -p "$PNG_DIR"
chmod +x "$NATIVE/native-sdl-build.sh" 2>/dev/null || true

# Product-truth capture uses the IO-only SDL host and requires a Li-produced RGB PPM.
# The legacy C paint_fb mirror is intentionally not used here.
bash "$NATIVE/native-sdl-build.sh" "$NATIVE/studio_shell_present_host.c" "$BIN"

run_one() {
  local slug="$1"
  local pid="$2"
  local tmp
  tmp="$(mktemp -d)"
  local ppm="$tmp/${slug}.ppm"
  local png="$tmp/${slug}.png"
  local json
  # Expect the Li rasterizer to write the RGB PPM to $ppm for this profile.
  # This repo intentionally does not attempt to generate the PPM via C mirror.
  if [[ ! -f "$ppm" ]]; then
    if [[ "${STUDIO_VERTICALS_ALLOW_SOLID_FALLBACK:-0}" == "1" ]]; then
      # Host will fall back to solid background (pixel_source=surface_io_only).
      :
    else
      echo "studio-verticals-capture-native: missing Li PPM for $slug ($ppm). Set STUDIO_VERTICALS_ALLOW_SOLID_FALLBACK=1 to soft-run." >&2
      rm -rf "$tmp"
      return 1
    fi
  fi
  if ! json=$("$BIN" --width "$WIDTH" --height "$HEIGHT" --rgb-ppm "$ppm" --screenshot "$ppm" 2>/dev/null); then
    rm -rf "$tmp"
    return 1
  fi
  if ! echo "$json" | grep -q '"native_pixels":1'; then
    rm -rf "$tmp"
    return 1
  fi
  if [[ ! -f "$ppm" ]]; then
    rm -rf "$tmp"
    return 1
  fi
  if ! python3 "$ROOT/scripts/studio-ppm-to-png.py" "$tmp" "$tmp" >/dev/null 2>&1; then
    rm -rf "$tmp"
    return 1
  fi
  if [[ -f "$tmp/${slug}.png" ]]; then
    cp "$tmp/${slug}.png" "$PNG_DIR/${slug}.png"
  else
    rm -rf "$tmp"
    return 1
  fi
  rm -rf "$tmp"
  echo "$json"
  return 0
}

native_ok=0
lines=()
set +u
for entry in "${VERTICALS[@]}"; do
  slug="${entry%%:*}"
  pid="${entry##*:}"
  if line=$(run_one "$slug" "$pid"); then
    native_ok=$((native_ok + 1))
    lines+=("$line")
    echo "studio-verticals-capture-native: $slug native_pixels=1"
  else
    echo "studio-verticals-capture-native: $slug FAILED" >&2
  fi
done

set -u
py_args=("$META" "$PNG_DIR" "$native_ok")
if ((${#lines[@]} > 0)); then
  py_args+=("${lines[@]}")
fi
python3 - "${py_args[@]}" <<'PY'
import json, sys
from pathlib import Path

meta = Path(sys.argv[1])
png_dir = Path(sys.argv[2])
count = int(sys.argv[3])
rows = []
for raw in sys.argv[4:]:
    try:
        rows.append(json.loads(raw))
    except json.JSONDecodeError:
        rows.append({"raw": raw})
pngs = sorted(png_dir.glob("*.png"))
meta.parent.mkdir(parents=True, exist_ok=True)
paint_blit_n = sum(1 for r in rows if r.get("capture_mode") == "paint_blit")
chip_only_n = sum(1 for r in rows if r.get("capture_mode") == "cpu_chip_only")
surface_only_n = sum(1 for r in rows if r.get("pixel_source") == "surface_io_only")
meta.write_text(
    json.dumps(
        {
            "status": "pass" if count >= 2 else "fail",
            "native_pixels": count > 0,
            "verticals_native": count,
            "png_count": len(pngs),
            "png_dir": str(png_dir),
            "requires_min_verticals": 2,
            "capture_paint_blit": paint_blit_n,
            "capture_cpu_chip_only": chip_only_n,
            "capture_surface_io_only": surface_only_n,
            "note": "product-truth capture expects Li RGB PPM input (pixel_source=li_rgb_ppm) and uses studio_shell_present_host (SDL IO only).",
            "frames": rows,
        },
        indent=2,
    )
    + "\n",
    encoding="utf-8",
)
print(json.dumps({"native_pixels": count > 0, "verticals_native": count, "png_count": len(pngs)}))
PY

if [[ "$native_ok" -lt 2 ]]; then
  echo "studio-verticals-capture-native: need game + one sim profile (got $native_ok)" >&2
  exit 1
fi
