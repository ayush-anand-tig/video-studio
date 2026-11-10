#!/bin/sh
# A quick listen before committing to a voice: synthesizes one sample line in each candidate
# (provider[:voice]) back to back in one file, each announced by name first (via `say`,
# always available), so you compare by ear instead of guessing from voice.env's comments.
#
# Usage (run from $K, the skill folder):
#   tools/preview-voice.sh "<sample line>" [out.wav [provider[:voice] ...]]
# With no candidates named, compares say, kokoro and phonon (whichever are actually
# installed — one that fails to synthesize is skipped with a note, not fatal to the rest).
# To filter candidates you must also name out.wav (even the default name) — see
# preview-signature.sh's usage comment for why.
set -eu
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TXT="${1:?Usage: preview-voice.sh \"<sample line>\" [out.wav [provider[:voice] ...]]}"
OUT="${2:-voice-preview.wav}"
shift; [ $# -gt 0 ] && shift || true
if [ $# -gt 0 ]; then CANDIDATES="$*"; else CANDIDATES="say kokoro phonon"; fi

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
echo "$TXT" > "$W/sample.txt"
: > "$W/list.txt"
n=0; skipped=""
for cand in $CANDIDATES; do
  n=$((n + 1))
  provider="${cand%%:*}"
  if [ "$provider" = "$cand" ]; then voice=""; else voice="${cand#*:}"; fi

  label_aiff="$W/$(printf %02d $n)-label.aiff"; label_wav="$W/$(printf %02d $n)-label.wav"
  say -o "$label_aiff" "$provider${voice:+, voice $voice}"
  ffmpeg -v error -y -i "$label_aiff" -ar 24000 -ac 1 "$label_wav"

  clip_raw="$W/$(printf %02d $n)-clip-raw.wav"; clip="$W/$(printf %02d $n)-clip.wav"
  if TTS_PROVIDER="$provider" LOCAL_VOICE="$voice" "$HERE/tools/tts.sh" "$W/sample.txt" "$clip_raw" \
      >/dev/null 2>"$W/$(printf %02d $n).err"; then
    ffmpeg -v error -y -i "$clip_raw" -ar 24000 -ac 1 "$clip"
    printf "file '%s'\nfile '%s'\n" "$label_wav" "$clip" >> "$W/list.txt"
  else
    skipped="$skipped $cand"
    echo "skipped $cand: $(tail -1 "$W/$(printf %02d $n).err")" >&2
  fi
done

[ -s "$W/list.txt" ] || { echo "No candidate synthesized. See errors above." >&2; exit 1; }
ffmpeg -v error -y -f concat -safe 0 -i "$W/list.txt" "$OUT"
echo "-> $OUT (candidates: $CANDIDATES)"
[ -z "$skipped" ] || echo "skipped (not installed / failed):$skipped"
