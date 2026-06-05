#!/usr/bin/env bash
# Exit 0 when lic demo-recorder Phase 2 branch is merged to main (or PR merged).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/_studio-env.sh"

PHASE2_BRANCH="${WORLD_STUDIO_DEMO_RECORDER_LIC_PHASE2_BRANCH:-cursor/world-studio-gui-demo-recorder-phase2}"
LIC_REMOTE="${LIC_ROOT:-../lic}"

if [[ ! -d "$LIC_REMOTE/.git" ]]; then
  echo "phase2-merge-gate: LIC_ROOT missing ($LIC_REMOTE)" >&2
  exit 1
fi

git -C "$LIC_REMOTE" fetch origin main "$PHASE2_BRANCH" --prune 2>/dev/null || git -C "$LIC_REMOTE" fetch origin --prune

tip="$(git -C "$LIC_REMOTE" rev-parse "origin/${PHASE2_BRANCH}" 2>/dev/null || true)"
main="$(git -C "$LIC_REMOTE" rev-parse origin/main 2>/dev/null || true)"
if [[ -z "$tip" || -z "$main" ]]; then
  echo "phase2-merge-gate: cannot resolve origin/${PHASE2_BRANCH} or origin/main" >&2
  exit 1
fi

if git -C "$LIC_REMOTE" merge-base --is-ancestor "$tip" "$main"; then
  echo "phase2-merge-gate: OK (${PHASE2_BRANCH} merged into main)"
  exit 0
fi

if command -v gh >/dev/null 2>&1; then
  if gh pr list --repo li-langverse/lic --head "$PHASE2_BRANCH" --state merged --limit 1 --json number -q '.[0].number' 2>/dev/null | grep -qE '^[0-9]+$'; then
    echo "phase2-merge-gate: OK (merged PR on lic)"
    exit 0
  fi
fi

echo "phase2-merge-gate: pending — ${PHASE2_BRANCH} (${tip:0:8}) not on origin/main (${main:0:8})" >&2
exit 1