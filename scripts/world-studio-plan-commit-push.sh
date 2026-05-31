#!/usr/bin/env bash
# Commit World Studio plan iteration and push WORLD_STUDIO_PR_BRANCH.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BRANCH="${WORLD_STUDIO_PR_BRANCH:-cursor/world-studio-master-plan-loop}"
TODO_ID="${1:-world-studio-iteration}"
MSG="${2:-feat(studio): ${TODO_ID} — world studio plan iteration}"

cd "$ROOT"
if [[ "$(git branch --show-current)" != "$BRANCH" ]]; then
  git fetch origin "$BRANCH" 2>/dev/null || true
  git checkout -B "$BRANCH" "origin/${BRANCH}" 2>/dev/null || git checkout -B "$BRANCH"
fi

git add -A
git reset -q HEAD -- 'deploy/studio-demo/screenshots/png/' 'data/world-studio-plan-loop/artifacts/' 2>/dev/null || true
git reset -q HEAD -- '*.mp4' 'deploy/studio-demo/screenshots/studio-live-simulation.html' 2>/dev/null || true

if git diff --cached --quiet; then
  echo "world-studio-plan-commit-push: nothing to commit"
else
  git commit -m "$MSG"
fi

TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
if [[ -z "$TOKEN" ]]; then
  echo "world-studio-plan-commit-push: no GH_TOKEN — skip push" >&2
  exit 0
fi
git push "https://x-access-token:${TOKEN}@github.com/li-langverse/lic.git" "HEAD:${BRANCH}"
echo "world-studio-plan-commit-push: pushed ${BRANCH}"
