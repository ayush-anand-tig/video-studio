#!/bin/sh
# Drafts the script or scene code using whichever backend providers.env picks.
# Usage: draft.sh <script|scene> <prompt-file>
#
# PROVIDER=agent (default): does nothing but print the prompt back — the calling agent
#   (Claude Code) writes the draft itself using its own reasoning.
# PROVIDER=local: runs the matching Ollama model and prints its draft to stdout. Treat
#   this as a rough first pass — review and tighten it before locking the script or
#   shipping the scene, the same way you would a junior draft.
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/../providers.env"

ROLE="${1:?Usage: draft.sh <script|scene> <prompt-file>}"
PROMPT_FILE="${2:?Usage: draft.sh <script|scene> <prompt-file>}"

if [ "${PROVIDER:-agent}" != "local" ]; then
  echo "PROVIDER=agent: write this yourself using the prompt in $PROMPT_FILE" >&2
  exit 2
fi

command -v ollama >/dev/null 2>&1 || {
  echo "PROVIDER=local but ollama isn't installed or on PATH. Install it, or set PROVIDER=agent in providers.env." >&2
  exit 2
}

case "$ROLE" in
  script) MODEL="${LOCAL_SCRIPT_MODEL:-qwen2.5:14b}" ;;
  scene)  MODEL="${LOCAL_CODE_MODEL:-qwen2.5-coder:14b}" ;;
  *) echo "Unknown role '$ROLE' — use 'script' or 'scene'" >&2; exit 2 ;;
esac

ollama list | grep -q "^${MODEL%%:*}" || echo "Note: $MODEL not in 'ollama list' yet — this will pull it first." >&2
ollama run "$MODEL" "$(cat "$PROMPT_FILE")"
