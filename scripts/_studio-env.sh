#!/usr/bin/env bash
# Studio repo path helpers — lic compiler and packages live in sibling ../lic (or LIC_ROOT).
set -euo pipefail

_studio_env_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

if [[ -z "${STUDIO_ROOT:-}" ]]; then
  # Avoid inheriting a global $ROOT env var (common in runners / shells) which would
  # break path resolution for this repo. The studio root is always the directory
  # containing this script's parent.
  STUDIO_ROOT="$(_studio_env_root)"
fi

if [[ -z "${LIC_ROOT:-}" ]]; then
  if [[ -n "${LIC_ROOT_OVERRIDE:-}" && -d "$LIC_ROOT_OVERRIDE" ]]; then
    LIC_ROOT="$(cd "$LIC_ROOT_OVERRIDE" && pwd)"
  elif [[ -d "$STUDIO_ROOT/../../../../../../../lic/packages/li-ui" ]]; then
    # Isolated agent workspace → developer li/lic monorepo sibling (prefer over partial ../lic).
    LIC_ROOT="$(cd "$STUDIO_ROOT/../../../../../../../lic" && pwd)"
  elif [[ -d "$STUDIO_ROOT/../lic/packages/li-ui" ]]; then
    LIC_ROOT="$(cd "$STUDIO_ROOT/../lic" && pwd)"
  elif [[ -d "$STUDIO_ROOT/../lic" ]]; then
    LIC_ROOT="$(cd "$STUDIO_ROOT/../lic" && pwd)"
  else
    echo "_studio-env: lic sibling not found (set LIC_ROOT or LIC_ROOT_OVERRIDE)" >&2
    return 1 2>/dev/null || exit 1
  fi
fi

# li.toml path deps use ../lic/packages/* — ensure sibling link in isolated workspaces.
_ensure_lic_sibling_link() {
  local link="$STUDIO_ROOT/../lic"
  local lic_real link_real
  lic_real="$(cd "$LIC_ROOT" && pwd)"
  link_real="$(cd "$link" 2>/dev/null && pwd || true)"
  if [[ -n "$link_real" && "$lic_real" == "$link_real" ]]; then
    return 0
  fi
  if [[ -e "$link" && ! -L "$link" ]]; then
    if [[ -n "$link_real" && "$lic_real" != "$link_real" ]]; then
      if command -v cmd.exe >/dev/null 2>&1; then
        cmd.exe //c "rmdir /s /q \"$(cygpath -w "$link" 2>/dev/null || echo "$link")\"" 2>/dev/null || true
      fi
      rm -rf "$link" 2>/dev/null || true
    fi
    if [[ -e "$link" && ! -L "$link" ]]; then
      echo "_studio-env: warn partial ../lic blocks symlink; using LIC_ROOT=$LIC_ROOT" >&2
      return 0
    fi
  elif [[ -L "$link" ]]; then
    rm -f "$link"
  fi
  ln -sf "$LIC_ROOT" "$link" 2>/dev/null || true
}
_ensure_lic_sibling_link

export STUDIO_ROOT LIC_ROOT

resolve_lic() {
  local c
  # Prefer native build/ over WSL cross-build (build-wsl may need newer glibc on Linux hosts).
  for c in \
    "$LIC_ROOT/build/compiler/lic/lic" \
    "$LIC_ROOT/build/compiler/lic/lic.exe" \
    "$LIC_ROOT/out/compiler/lic/lic" \
    "$LIC_ROOT/build-wsl/compiler/lic/lic" \
    "$LIC_ROOT/build-wsl/compiler/lic/lic.exe"; do
    if [[ -f "$c" && -x "$c" ]]; then
      echo "$c"
      return 0
    fi
  done
  if [[ -x "$LIC_ROOT/scripts/resolve-lic.sh" ]]; then
    local resolved
    resolved="$("$LIC_ROOT/scripts/resolve-lic.sh" 2>/dev/null || true)"
    if [[ -n "$resolved" && -f "$resolved" && -x "$resolved" ]]; then
      echo "$resolved"
      return 0
    fi
  fi
  return 1
}
