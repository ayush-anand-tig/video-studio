#!/bin/zsh
# Checks tools and installs the video-style-kit skill for Claude Code (symlink, so edits stay in git).
set -euo pipefail
cd "$(dirname "$0")"
for t in node npx ffmpeg ffprobe; do command -v $t >/dev/null && echo "ok: $t" || { echo "MISSING: $t  (brew install node ffmpeg)"; exit 1; }; done
mkdir -p "$HOME/.claude/skills"
L="$HOME/.claude/skills/video-style-kit"
KIT="$(pwd -P)/video-style-kit"
if [[ -L "$L" ]]; then
  [[ "$(cd "$L" 2>/dev/null && pwd -P)" == "$KIT" ]] && echo "ok: $L -> $KIT" || { echo "STOP: $L points elsewhere or is broken. Remove it (rm \"$L\") and re-run."; exit 1; }
elif [[ -e "$L" ]]; then echo "STOP: $L exists and isn't a link to this kit. Move it away and re-run."; exit 1
else ln -s "$KIT" "$L"; echo "linked: $L -> $KIT"; fi
[[ -f LESSONS.md ]] || printf '# Lessons\n\nOne line per lesson, newest first. The skill reads this before every video.\n' > LESSONS.md

echo "Voice (informational, none of this is required — video-style-kit/voice.env picks the default):"
command -v say >/dev/null && echo "  ok: say (macOS built-in TTS)"
python3 -c "import kokoro_onnx" 2>/dev/null && echo "  ok: kokoro-onnx" || echo "  not installed: kokoro-onnx (pip install kokoro-onnx soundfile, for better local voice quality)"
python3 -c "import faster_whisper" 2>/dev/null && echo "  ok: faster-whisper" || echo "  not installed: faster-whisper (pip install faster-whisper, for word-level timestamps)"

echo "Done. Start a new Claude Code session here and say: make a 20-second video about <topic>"
