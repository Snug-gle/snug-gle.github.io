#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTENT="$REPO_DIR/content"

# Vault 경로 결정: 환경변수 → .sync-config → 오류
if [ -n "${OBSIDIAN_VAULT:-}" ]; then
  VAULT="$OBSIDIAN_VAULT"
elif [ -f "$REPO_DIR/.sync-config" ]; then
  VAULT="$(cat "$REPO_DIR/.sync-config")"
else
  echo "Error: Obsidian vault path not configured." >&2
  echo "" >&2
  echo "  Option 1: export OBSIDIAN_VAULT=/path/to/vault" >&2
  echo "  Option 2: echo '/path/to/vault' > $REPO_DIR/.sync-config" >&2
  exit 1
fi

if [ ! -d "$VAULT" ]; then
  echo "Error: Vault directory not found: $VAULT" >&2
  exit 1
fi

echo "Vault : $VAULT"
echo "Content: $CONTENT"

node "$REPO_DIR/ensure-dates.mjs" "$VAULT"

rsync -av --delete --delete-excluded \
  --exclude=".git/" \
  --exclude=".obsidian/" \
  --exclude=".idea/" \
  --exclude=".makemd/" \
  --exclude=".claude.json" \
  --exclude=".links/" \
  --exclude="private/" \
  --exclude="templates/" \
  --exclude="archive/" \
  --exclude="area/work/" \
  --exclude="area/log/" \
  --exclude="area/learning/" \
  --exclude="area/career/interview-prep/" \
  --exclude="area/career/portfolio-resume.md" \
  --exclude="project/inbox/" \
  --exclude="project/pending/" \
  --exclude="resource/daily/" \
  --exclude="*.base" \
  --exclude="*.url" \
  --exclude="*.canvas" \
  --exclude="CLAUDE.md" \
  --exclude="GEMINI.md" \
  --exclude="GEMINI-MCP-SETUP.md" \
  --exclude="README.md" \
  --exclude="PUBLISHING.md" \
  --exclude="AUTOMATION-EXAMPLES.md" \
  --exclude="VAULT-IMPROVEMENT-PLAN.md" \
  --exclude="VAULT-TRANSFORMATION-COMPLETE.md" \
  "$VAULT/" "$CONTENT/"
