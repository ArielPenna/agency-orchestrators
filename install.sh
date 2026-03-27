#!/usr/bin/env bash
set -euo pipefail

DEST="${HOME}/.config/opencode/agents"
SRC="$(cd "$(dirname "$0")/agents" && pwd)"

if [[ ! -d "$SRC" ]]; then
  echo "Error: agents/ directory not found next to install.sh" >&2
  exit 1
fi

mkdir -p "$DEST"
cp "$SRC"/*.md "$DEST/"

COUNT=$(ls "$SRC"/*.md | wc -l | tr -d ' ')
echo "✅ Installed $COUNT agents to $DEST"
echo "   Restart OpenCode to load the new agents."
