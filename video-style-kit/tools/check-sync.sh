#!/bin/sh
# Checks whether narration timing actually lines up with each beat's visual cue time —
# catches the common mistake of writing a script sized for the WORDS without checking
# it's sized for the on-screen TIMING.
#
# Usage: check-sync.sh <beats.json> [--threshold seconds]
# beats.json: a JSON array, order = screen order:
#   [{"beat":"hook","t":0.0,"text":"Why did GPU prices jump?"}, ...]
#   t = that beat's visual start time in seconds, taken from the GSAP timeline / cues map.
#
# Synthesizes each line with the project's real tts.sh (same TTS_PROVIDER/voice the actual
# video would use), measures how long each one actually takes to say, and checks whether
# back-to-back narration would land inside each beat's visual window. This is an
# approximation (it times each line synthesized alone, not a real forced-alignment of one
# continuous take) — good enough to catch a badly-paced beat map, not a substitute for
# TRANSCRIBE_PROVIDER=whisper once real word-level timestamps are wired into a project.
set -eu
HERE="$(cd "$(dirname "$0")/.." && pwd)"
BEATS="${1:?Usage: check-sync.sh <beats.json> [--threshold seconds]}"
THRESHOLD=1.0
[ "${2:-}" = "--threshold" ] && THRESHOLD="${3:?--threshold needs a number}"

command -v jq >/dev/null 2>&1 || { echo "Needs jq." >&2; exit 1; }
[ -f "$BEATS" ] || { echo "No such file: $BEATS" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

n=$(jq 'length' "$BEATS")
cum=0
fail=0
printf "%-10s %10s %10s %9s  %-6s  %s\n" "beat" "visual_t" "audio_at" "drift" "status" "text"
i=0
while [ "$i" -lt "$n" ]; do
  beat=$(jq -r ".[$i].beat" "$BEATS")
  t=$(jq -r ".[$i].t" "$BEATS")
  text=$(jq -r ".[$i].text" "$BEATS")
  printf '%s' "$text" > "$WORK/$beat.txt"
  "$HERE/tools/tts.sh" "$WORK/$beat.txt" "$WORK/$beat.wav" >/dev/null 2>"$WORK/$beat.err" \
    || { echo "tts.sh failed on beat '$beat':" >&2; cat "$WORK/$beat.err" >&2; exit 1; }
  dur=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$WORK/$beat.wav")
  drift=$(echo "$cum - $t" | bc)
  absdrift=$(echo "$drift" | tr -d '-')
  status="ok"
  if [ "$(echo "$absdrift > $THRESHOLD" | bc)" = "1" ]; then status="DRIFT"; fail=1; fi
  printf "%-10s %10.2f %10.2f %9.2f  %-6s  %s\n" "$beat" "$t" "$cum" "$drift" "$status" "$text"
  cum=$(echo "$cum + $dur" | bc)
  i=$((i+1))
done

echo
if [ "$fail" = "1" ]; then
  echo "FAIL: narration drifts more than ${THRESHOLD}s from the visual timeline on at least one beat."
  echo "Fix by retiming the beats to match how long the narration actually takes (easiest), or by"
  echo "driving the beats from real word-level timestamps (TRANSCRIBE_PROVIDER=whisper) instead of"
  echo "fixed seconds — see references/production.md's cue-map note."
  exit 1
fi
echo "OK: narration stays within ${THRESHOLD}s of every beat's visual start."
