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

# GNU rsync 우선 사용 (macOS 기본 openrsync는 --exclude-from 미지원)
RSYNC=$(command -v /opt/homebrew/bin/rsync || command -v /usr/local/bin/rsync || command -v rsync)

"$RSYNC" -av --delete --delete-excluded \
  --exclude-from="$REPO_DIR/.syncignore" \
  "$VAULT/" "$CONTENT/"
