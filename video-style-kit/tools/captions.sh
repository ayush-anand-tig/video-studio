#!/bin/sh
# Captions from the data that already times the picture, not a separate system: the text
# is beats.json's (the script, spelled right, where a transcript might mishear a product
# name), and the timing comes from audio/words.json when it exists, otherwise each beat's t.
#
# Usage (run from projects/<slug>/): captions.sh [--max-chars N] [--check]
#   Writes src/captions.json (read by a burned-in caption layer, like cues.json) plus the
#   sidecar deliverables exports/captions.srt and exports/captions.vtt.
#   --max-chars  longest cue, default 42 (one subtitle line). Use ~28 for burned 9:16.
#   --check      writes nothing; exits 1 if the existing files are out of date (reuses the
#                --max-chars recorded in exports/captions.vtt).
set -eu
MAX=""; CHECK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --max-chars) MAX="${2:?--max-chars needs a number}"; shift 2 ;;
    --check) CHECK=1; shift ;;
    *) echo "Usage: captions.sh [--max-chars N] [--check]" >&2; exit 1 ;;
  esac
done
command -v jq >/dev/null 2>&1 || { echo "Needs jq." >&2; exit 1; }
[ -f beats.json ] && [ -f audio/vo.wav ] || { echo "Run from projects/<slug>/ after Phase 2 Voice (needs beats.json, audio/vo.wav)." >&2; exit 1; }
[ -z "$MAX" ] && [ "$CHECK" = 1 ] && MAX=$(sed -n 's/^NOTE max-chars=//p' exports/captions.vtt 2>/dev/null | head -1)
MAX="${MAX:-42}"

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
VO=$(ffprobe -v error -show_entries format=duration -of csv=p=0 audio/vo.wav)
if [ -f audio/words.json ]; then cp audio/words.json "$W/words.json"; SRC="words.json"; else echo '[]' > "$W/words.json"; SRC="each beat's t (no words.json)"; fi

# Each beat spans [t, next t), trimmed to its last spoken word when words.json exists. Its
# text splits at sentence ends, then each sentence into near-equal chunks of <= MAX chars
# (no one-word orphans), and the span is shared among the chunks by length.
jq --argjson max "$MAX" --argjson vo "$VO" --slurpfile words "$W/words.json" '
  def balanced:
    (length / $max | ceil) as $n | (length / $n) as $goal
    | reduce (split(" ") | map(select(length > 0)))[] as $w ({out: [], cur: ""};
        (if .cur == "" then $w else .cur + " " + $w end) as $try
        | if .cur == "" or (($try | length) <= $max and (($try | length) - $goal | fabs) < ((.cur | length) - $goal | fabs))
          then .cur = $try else {out: (.out + [.cur]), cur: $w} end)
    | .out + [.cur];
  def chunks: [splits("(?<=[.?!])\\s+") | select(length > 0) | balanced[]];
  def ms: . * 1000 | round / 1000;
  $words[0] as $ws | . as $b
  | [range(0; length) as $i
      | ($b[$i + 1].t // $vo) as $next
      | ([$ws[] | select(.start >= $b[$i].t - 0.3 and .start < $next - 0.05) | .end] | max) as $last
      | (if $last != null and $last > $b[$i].t then [$last + 0.3, $next] | min else $next end) as $end
      | ($b[$i].text | chunks) as $ch
      | ($ch | map(length + 1) | add) as $tot
      | foreach $ch[] as $x ({a: 0, z: 0}; {a: .z, z: (.z + ($x | length) + 1)};
          {start: ($b[$i].t + ($end - $b[$i].t) * .a / $tot | ms),
           end:   ($b[$i].t + ($end - $b[$i].t) * .z / $tot | ms), text: $x})]
' beats.json > "$W/captions.json"

TS='def p($n): tostring | ("000" + .) | .[-$n:];
    def ts($s): (. * 1000 | round) as $m
      | "\($m / 3600000 | floor | p(2)):\(($m % 3600000) / 60000 | floor | p(2)):\(($m % 60000) / 1000 | floor | p(2))\($s)\($m % 1000 | p(3))";'
jq -r "$TS"' to_entries[] | "\(.key + 1)\n\(.value.start | ts(",")) --> \(.value.end | ts(","))\n\(.value.text)\n"' "$W/captions.json" > "$W/captions.srt"
{ printf 'WEBVTT\n\nNOTE max-chars=%s\n\n' "$MAX"; jq -r "$TS"' .[] | "\(.start | ts(".")) --> \(.end | ts("."))\n\(.text | gsub("&"; "&amp;") | gsub("<"; "&lt;"))\n"' "$W/captions.json"; } > "$W/captions.vtt"

if [ "$CHECK" = 1 ]; then
  for f in src/captions.json exports/captions.srt exports/captions.vtt; do
    cmp -s "$W/${f##*/}" "$f" || { echo "STALE: $f is missing or out of date. Re-run captions.sh (and re-render if they're burned in)."; exit 1; }
  done
  echo "OK: captions match beats.json and the current timing."
  exit 0
fi

mkdir -p src exports
cp "$W/captions.json" src/captions.json
cp "$W/captions.srt" exports/captions.srt
cp "$W/captions.vtt" exports/captions.vtt
jq -r --arg src "$SRC" --argjson vo "$VO" '"\(length) cues, timed by \($src); longest \(map(.text | length) | max) chars; last ends \(.[-1].end)s (vo.wav \($vo | . * 100 | round / 100)s)"' src/captions.json
echo "-> src/captions.json, exports/captions.srt, exports/captions.vtt"
