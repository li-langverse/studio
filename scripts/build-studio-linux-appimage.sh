#!/usr/bin/env bash
# Build Linux AppDir + optional AppImage for Li World Studio (wsg-w5-linux-appimage).
# Bundles SDL2 next to the I/O-only present host; wgpu env set at launch.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NATIVE="$ROOT/deploy/studio-demo/native"
SRC="$NATIVE/studio_shell_present_host.c"
HOST_BIN="$NATIVE/studio_shell_present_host"
APPDIR="$ROOT/installer/out/LiWorldStudio.AppDir"
APPIMAGE="$ROOT/installer/out/LiWorldStudio-x86_64.AppImage"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "build-studio-linux-appimage: skip (not Linux)" >&2
  exit 0
fi

if [[ ! -f "$SRC" ]]; then
  echo "build-studio-linux-appimage: missing $SRC" >&2
  exit 1
fi

build_host() {
  if [[ -x "$HOST_BIN" && "$SRC" -ot "$HOST_BIN" ]]; then
    echo "build-studio-linux-appimage: present host up to date"
    return 0
  fi
  if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists sdl2 2>/dev/null; then
    # shellcheck disable=SC2046
    gcc -std=c11 -Wall -Wextra -O2 "$SRC" -o "$HOST_BIN" $(pkg-config --cflags --libs sdl2)
  elif command -v sdl2-config >/dev/null 2>&1; then
    # shellcheck disable=SC2046
    gcc -std=c11 -Wall -Wextra -O2 "$SRC" -o "$HOST_BIN" $(sdl2-config --cflags --libs)
  else
    echo "build-studio-linux-appimage: install SDL2 (apt install libsdl2-dev)" >&2
    exit 4
  fi
  chmod +x "$HOST_BIN"
  echo "build-studio-linux-appimage: built $HOST_BIN"
}

bundle_sdl_libs() {
  local dest="$APPDIR/usr/lib"
  mkdir -p "$dest"
  if ! command -v ldd >/dev/null 2>&1; then
    return 0
  fi
  while IFS= read -r lib; do
    [[ -f "$lib" ]] || continue
    case "$lib" in
      /lib/*|/lib64/*|/usr/lib/*|/usr/lib64/*) cp -n "$lib" "$dest/" 2>/dev/null || cp "$lib" "$dest/" ;;
    esac
  done < <(ldd "$HOST_BIN" 2>/dev/null | awk '/=> \// {print $3}' | grep -E 'libSDL|libGL|libX|libwayland|libdecor|libasound|libpulse|libdrm|libgbm' || true)
}

write_apprun() {
  cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
set -eu
HERE="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
export PATH="$HERE/usr/bin:$PATH"
export LD_LIBRARY_PATH="$HERE/usr/lib:${LD_LIBRARY_PATH:-}"
export LIG_HOST_PRESENT=1
export LIG_WGPU_SWAPCHAIN=1
export LIG_GPU_RUNNER=1
exec "$HERE/usr/bin/studio_shell_present_host" "$@"
EOF
  chmod +x "$APPDIR/AppRun"
}

write_desktop() {
  mkdir -p "$APPDIR/usr/share/applications"
  cp "$ROOT/installer/linux/li-world-studio.desktop" "$APPDIR/usr/share/applications/li-world-studio.desktop"
  cp "$APPDIR/usr/share/applications/li-world-studio.desktop" "$APPDIR/li-world-studio.desktop"
}

build_host
mkdir -p "$APPDIR/usr/bin"
cp -f "$HOST_BIN" "$APPDIR/usr/bin/studio_shell_present_host"
bundle_sdl_libs
write_apprun
write_desktop

if command -v appimagetool >/dev/null 2>&1; then
  ARCH=x86_64 appimagetool "$APPDIR" "$APPIMAGE"
  echo "build-studio-linux-appimage: wrote $APPIMAGE"
elif [[ -x "$ROOT/../lic/scripts/fetch-appimagetool.sh" ]]; then
  bash "$ROOT/../lic/scripts/fetch-appimagetool.sh" 2>/dev/null || true
  if command -v appimagetool >/dev/null 2>&1; then
    ARCH=x86_64 appimagetool "$APPDIR" "$APPIMAGE"
    echo "build-studio-linux-appimage: wrote $APPIMAGE"
  else
    echo "build-studio-linux-appimage: AppDir ready at $APPDIR (appimagetool not installed)"
  fi
else
  echo "build-studio-linux-appimage: AppDir ready at $APPDIR (install appimagetool for .AppImage)"
fi
