#!/usr/bin/env bash
# WP-UX-14b — verify Li-native pixel path; C hosts remain fenced until step 4 deletion.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/li-ui.sh
source "$ROOT/scripts/lib/li-ui.sh"
export LI_REPO_ROOT="$ROOT"

fail() { li_gate_fail "$*"; exit 1; }

li_phase "c-host deprecation doc"
[[ -f "$ROOT/deploy/studio-demo/native/DEPRECATED.md" ]] || fail "missing deploy/studio-demo/native/DEPRECATED.md"
[[ -f "$ROOT/docs/game-dev/specs/c-host-retirement-plan.md" ]] || fail "missing c-host-retirement-plan.md"

li_phase "c-host retirement smokes"
for smoke in \
  li-tests/smoke/studio_c_host_retirement_gate.li \
  li-tests/smoke/studio_native_pixels_honesty.li \
  packages/li-render/li-tests/smoke/native_pixels_honesty.li; do
  [[ -f "$ROOT/$smoke" ]] || fail "missing smoke $smoke"
done

LIC="${LIC:-}"
if [[ -x "$LIC_ROOT/build/compiler/lic/lic" ]]; then
  LIC="$LIC_ROOT/build/compiler/lic/lic"
elif [[ -x "$LIC_ROOT/scripts/resolve-lic.sh" ]]; then
  LIC="$("$LIC_ROOT/scripts/resolve-lic.sh" 2>/dev/null)" || true
fi

if [[ -n "$LIC" && -x "$LIC" ]]; then
  li_phase "lic check c-host retirement"
  "$LIC" check "$ROOT/li-tests/smoke/studio_c_host_retirement_gate.li" \
    || fail "lic check studio_c_host_retirement_gate.li"
else
  li_warn "lic not built — smoke paths verified only"
fi

li_ok "studio-c-host-retirement-gate"
