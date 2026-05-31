#!/usr/bin/env bash
# Studio repo path helpers — lic compiler and packages live in sibling ../lic (or LIC_ROOT).
set -euo pipefail

_studio_env_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

if [[ -z "${STUDIO_ROOT:-}" ]]; then
  STUDIO_ROOT="${ROOT:-$(_studio_env_root)}"
fi

if [[ -z "${LIC_ROOT:-}" ]]; then
  if [[ -n "${LIC_ROOT_OVERRIDE:-}" && -d "$LIC_ROOT_OVERRIDE" ]]; then
    LIC_ROOT="$(cd "$LIC_ROOT_OVERRIDE" && pwd)"
  elif [[ -d "$STUDIO_ROOT/../lic" ]]; then
    LIC_ROOT="$(cd "$STUDIO_ROOT/../lic" && pwd)"
  elif [[ -d "$STUDIO_ROOT/../../../../../../../lic" ]]; then
    # Isolated agent workspace → developer li/lic monorepo sibling.
    LIC_ROOT="$(cd "$STUDIO_ROOT/../../../../../../../lic" && pwd)"
  else
    echo "_studio-env: lic sibling not found (set LIC_ROOT or LIC_ROOT_OVERRIDE)" >&2
    return 1 2>/dev/null || exit 1
  fi
fi

# li.toml path deps use ../lic/packages/* — ensure sibling link in isolated workspaces.
_ensure_lic_sibling_link() {
  local link="$STUDIO_ROOT/../lic"
  if [[ -d "$LIC_ROOT" && "$LIC_ROOT" != "$(cd "$link" 2>/dev/null && pwd || true)" ]]; then
    if [[ ! -e "$link" ]]; then
      ln -sf "$LIC_ROOT" "$link" 2>/dev/null || true
    fi
  fi
}
_ensure_lic_sibling_link

export STUDIO_ROOT LIC_ROOT

resolve_lic() {
  local c
  for c in \
    "$LIC_ROOT/build-wsl/compiler/lic/lic" \
    "$LIC_ROOT/build-wsl/compiler/lic/lic.exe" \
    "$LIC_ROOT/build/compiler/lic/lic" \
    "$LIC_ROOT/build/compiler/lic/lic.exe"; do
    if [[ -f "$c" ]]; then
      echo "$c"
      return 0
    fi
  done
  if [[ -x "$LIC_ROOT/scripts/resolve-lic.sh" ]]; then
    "$LIC_ROOT/scripts/resolve-lic.sh" 2>/dev/null && return 0
  fi
  return 1
}
