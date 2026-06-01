#!/usr/bin/env bash
# WP-UX-14b — verify Li-native pixel path; C hosts remain fenced until step 4 deletion.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=_studio-env.sh
source "$ROOT/scripts/_studio-env.sh"
ROOT="$STUDIO_ROOT"

fail() { echo "FAIL: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }
ok() { echo "OK: $*"; }

ok "c-host deprecation doc"
[[ -f "$ROOT/deploy/studio-demo/native/DEPRECATED.md" ]] || fail "missing deploy/studio-demo/native/DEPRECATED.md"
[[ -f "$ROOT/docs/game-dev/specs/c-host-retirement-plan.md" ]] || fail "missing c-host-retirement-plan.md"

ok "c-host retirement smokes"
for smoke in \
  li-tests/smoke/studio_c_host_retirement_gate.li \
  li-tests/smoke/studio_native_pixels_honesty.li \
  li-tests/smoke/studio_c_host_slim.li; do
  [[ -f "$ROOT/$smoke" ]] || fail "missing smoke $smoke"
done
if [[ -f "$LIC_ROOT/packages/li-render/li-tests/smoke/native_pixels_honesty.li" ]]; then
  ok "li-render native_pixels_honesty smoke present"
else
  warn "li-render native_pixels_honesty smoke missing under LIC_ROOT"
fi

LIC_BIN="${LIC:-}"
if ! LIC_BIN="$(resolve_lic 2>/dev/null)"; then
  LIC_BIN=""
fi

if [[ -n "$LIC_BIN" && -x "$LIC_BIN" ]]; then
  ok "lic check c-host retirement"
  "$LIC_BIN" check "$ROOT/li-tests/smoke/studio_c_host_retirement_gate.li" \
    || fail "lic check studio_c_host_retirement_gate.li"
  if [[ -f "$LIC_ROOT/packages/li-studio/li-tests/smoke/studio_c_host_slim.li" ]]; then
    "$LIC_BIN" check "$LIC_ROOT/packages/li-studio/li-tests/smoke/studio_c_host_slim.li" \
      || fail "lic check studio_c_host_slim.li"
  elif [[ -f "$ROOT/li-tests/smoke/studio_c_host_slim.li" ]]; then
    "$LIC_BIN" check "$ROOT/li-tests/smoke/studio_c_host_slim.li" \
      || fail "lic check studio_c_host_slim.li"
  fi
else
  warn "lic not built — smoke paths verified only"
fi

ok "studio-c-host-retirement-gate"
