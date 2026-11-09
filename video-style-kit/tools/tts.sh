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

# Kokoro/Phonon need Python 3.10+; this machine's plain `python3` may be older (check
# `python3 --version`). PYTHON_BIN in voice.env or the environment overrides which
# interpreter local/phonon use — point it at a venv with the right packages installed if
# your default python3 is too old or doesn't have them.
PY="${PYTHON_BIN:-python3}"

case "${TTS_PROVIDER:-say}" in
  say)
    say -o "$OUT" --data-format=LEF32@22050 -f "$TEXT_FILE"
    echo "synthesized (macOS say) -> $OUT"
    ;;
  kokoro)
    MODEL_DIR="${KOKORO_MODEL_DIR:-$HOME/.cache/kokoro}"
    [ -f "$MODEL_DIR/kokoro-v1.0.onnx" ] || { echo "Kokoro model files not found at $MODEL_DIR. One-time setup: mkdir -p $MODEL_DIR && curl -fsSL -o $MODEL_DIR/kokoro-v1.0.onnx https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx && curl -fsSL -o $MODEL_DIR/voices-v1.0.bin https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin" >&2; exit 1; }
    "$PY" -c "
from kokoro_onnx import Kokoro
import soundfile as sf
text = open('$TEXT_FILE').read()
k = Kokoro('$MODEL_DIR/kokoro-v1.0.onnx', '$MODEL_DIR/voices-v1.0.bin')
samples, sr = k.create(text, voice='${LOCAL_VOICE:-af_heart}')
sf.write('$OUT', samples, sr)
" || { echo "Kokoro isn't installed. Run: pip install kokoro-onnx soundfile, or set TTS_PROVIDER=say." >&2; exit 1; }
    echo "synthesized (Kokoro, voice: ${LOCAL_VOICE:-af_heart}) -> $OUT"
    ;;
  phonon)
    "$PY" -c "
import ptts
text = open('$TEXT_FILE').read()
tts = ptts.TTS(ptts.DEFAULT_MODEL, lang='en')
tts.save('$OUT', text, voice='${LOCAL_VOICE:?Set LOCAL_VOICE to a phonon voice_id in voice.env}')
" || { echo "Phonon (ptts) isn't installed. Run: pip install ptts, or set TTS_PROVIDER=say. Note: the default English 31M model is Apache 2.0; other language variants may be CC BY-NC (non-commercial) — check before using." >&2; exit 1; }
    echo "synthesized (Phonon) -> $OUT"
    ;;
  kitten)
    "$PY" -c "
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
