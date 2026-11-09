#!/bin/sh
# Gets word-level timestamps off a voiceover file, for landing Bridge/Ripple/Timeline
# on the right word. Usage: transcribe.sh <audio.wav> <out.json>
set -eu
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/voice.env"

AUDIO="${1:?Usage: transcribe.sh <audio.wav> <out.json>}"
OUT="${2:?Usage: transcribe.sh <audio.wav> <out.json>}"

case "${TRANSCRIBE_PROVIDER:-none}" in
  none)
    echo "TRANSCRIBE_PROVIDER=none: no word-level timestamps available." >&2
    echo "Beats will fall back to roughly even timing across the audio's duration." >&2
    exit 2
    ;;
  whisper)
    python3 -c "
from faster_whisper import WhisperModel
import json
model = WhisperModel('small', device='cpu')
segments, _ = model.transcribe('$AUDIO', word_timestamps=True)
words = [{'word': w.word.strip(), 'start': w.start, 'end': w.end} for s in segments for w in s.words]
json.dump(words, open('$OUT', 'w'), indent=2)
" || { echo "faster-whisper isn't installed. Run: pip install faster-whisper, or set TRANSCRIBE_PROVIDER=none." >&2; exit 1; }
    echo "transcribed -> $OUT"
    ;;
  *)
    echo "Unknown TRANSCRIBE_PROVIDER: ${TRANSCRIBE_PROVIDER:-}" >&2; exit 1 ;;
esac
