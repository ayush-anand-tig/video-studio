#!/bin/sh
# Synthesizes voiceover audio using whichever backend voice.env picks.
# Usage: tts.sh <text-file> <out.wav>
set -eu
HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/voice.env"

TEXT_FILE="${1:?Usage: tts.sh <text-file> <out.wav>}"
OUT="${2:?Usage: tts.sh <text-file> <out.wav>}"
SECRETS="${VIDEO_STUDIO_SECRETS:-$HOME/.config/video-studio.env}"
[ -f "$SECRETS" ] && . "$SECRETS"

case "${TTS_PROVIDER:-say}" in
  say)
    say -o "$OUT" --data-format=LEF32@22050 -f "$TEXT_FILE"
    echo "synthesized (macOS say) -> $OUT"
    ;;
  kokoro)
    python3 -c "
import sys
from kokoro_onnx import Kokoro
import soundfile as sf
text = open('$TEXT_FILE').read()
k = Kokoro('kokoro-v1.0.onnx', 'voices-v1.0.bin')
samples, sr = k.create(text, voice='${LOCAL_VOICE:-af_heart}')
sf.write('$OUT', samples, sr)
" || { echo "Kokoro isn't installed. Run: pip install kokoro-onnx soundfile (and download the model/voices files per its README), or set TTS_PROVIDER=say." >&2; exit 1; }
    echo "synthesized (Kokoro) -> $OUT"
    ;;
  kitten)
    python3 -c "
from kittentts import KittenTTS
import soundfile as sf
text = open('$TEXT_FILE').read()
m = KittenTTS('KittenML/kitten-tts-nano-0.1')
audio = m.generate(text)
sf.write('$OUT', audio, 24000)
" || { echo "Kitten TTS isn't installed. Run: pip install kittentts soundfile, or set TTS_PROVIDER=say." >&2; exit 1; }
    echo "synthesized (Kitten TTS) -> $OUT"
    ;;
  elevenlabs)
    : "${ELEVENLABS_API_KEY:?Set ELEVENLABS_API_KEY in $SECRETS}"
    VOICE="${ELEVENLABS_VOICE_ID:-21m00Tcm4TlvDq8ikWAM}"
    curl -s "https://api.elevenlabs.io/v1/text-to-speech/$VOICE" \
      -H "xi-api-key: $ELEVENLABS_API_KEY" -H "Content-Type: application/json" \
      -d "$(python3 -c "import json,sys; print(json.dumps({'text': open('$TEXT_FILE').read(), 'model_id':'eleven_multilingual_v2'}))")" \
      -o "$OUT"
    echo "synthesized (ElevenLabs) -> $OUT"
    ;;
  *)
    echo "Unknown TTS_PROVIDER: ${TTS_PROVIDER:-}" >&2; exit 1 ;;
esac
