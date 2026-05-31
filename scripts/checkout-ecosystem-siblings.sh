#!/usr/bin/env bash
# Clone benchmarks (and optional lic) beside studio for UI/UX native capture CI.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PARENT="$(cd "$ROOT/.." && pwd)"
BENCHMARKS_ORG="${BENCHMARKS_ORG:-li-langverse/benchmarks}"
LIC_ORG="${LIC_ORG:-li-langverse/lic}"
REF="${ECOSYSTEM_REF:-main}"
BENCHMARKS_REF="${BENCHMARKS_REF:-main}"

clone_repo() {
  local slug="$1" dest="$2" ref="$3"
  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" fetch --depth 1 origin "$ref"
    git -C "$dest" checkout -q "$ref"
    git -C "$dest" reset -q --hard "origin/$ref"
  else
    git clone --depth 1 --branch "$ref" "https://github.com/${slug}.git" "$dest" \
      || git clone --depth 1 "https://github.com/${slug}.git" "$dest"
  fi
  chmod +x "$dest/scripts/"* 2>/dev/null || true
}

clone_repo "$BENCHMARKS_ORG" "$PARENT/benchmarks" "$BENCHMARKS_REF"

# Studio li.toml path deps expect ../lic — ensure sibling exists for capture gates.
if [[ ! -d "$PARENT/lic/packages/li-ui" ]]; then
  clone_repo "$LIC_ORG" "$PARENT/lic" "$REF"
fi

echo "ecosystem siblings: $PARENT/benchmarks $PARENT/lic (ref=${REF})"
