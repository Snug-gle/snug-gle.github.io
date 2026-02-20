#!/usr/bin/env bash
set -euo pipefail

VAULT="$(dirname "$0")/links/MyJourneyContinues"
CONTENT="$(dirname "$0")/content"

node "$(dirname "$0")/ensure-dates.mjs" "$VAULT"

rsync -av --delete --delete-excluded \
  --exclude=".git/" \
  --exclude=".obsidian/" \
  --exclude=".idea/" \
  --exclude=".makemd/" \
  --exclude=".claude.json" \
  --exclude="private/" \
  --exclude="templates/" \
  --exclude="links/" \
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
