#!/bin/sh
# One image for reviewing a cut: a tile per beat, grabbed 0.3 s before the next beat starts,
# when that beat's state is fully built and being read. That's where pacing, overlap and
# "did it land" problems show. Tiles are unlabeled (this ffmpeg may lack drawtext), so the
# tile-to-beat key is printed instead.
#
# Usage (run from projects/<slug>/): beat-sheet.sh <video> <out.jpg>
# Times come from src/cues.json (what the render used), in beats.json order.
set -eu
V="${1:?Usage: beat-sheet.sh <video> <out.jpg>}"
OUT="${2:?Usage: beat-sheet.sh <video> <out.jpg>}"
[ -f beats.json ] && [ -f src/cues.json ] || { echo "Run from projects/<slug>/ (needs beats.json, src/cues.json)." >&2; exit 1; }
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$V")

jq -r --slurpfile c src/cues.json --argjson d "$D" '
  [.[].beat] as $b | range(0; $b | length) as $i
  | ((if $i + 1 < ($b | length) then $c[0][$b[$i + 1]] else $d end) - 0.3) as $at
  | "\($i + 1) \($b[$i]) \(if $at < $c[0][$b[$i]] then $c[0][$b[$i]] else $at end)"' beats.json > "$W/key"

n=0
while read -r i beat at; do
  ffmpeg -v error -y -ss "$at" -i "$V" -frames:v 1 -vf scale=480:-2 "$W/$(printf %03d "$i").jpg"
  printf 'tile %-2s %-14s @ %.2fs\n' "$i" "$beat" "$at"
  n=$i
done < "$W/key"

cols=$(( n < 4 ? n : 4 )); rows=$(( (n + 3) / 4 ))
ffmpeg -v error -y -framerate 1 -i "$W/%03d.jpg" -vf "tile=${cols}x${rows}:padding=6:color=white" -frames:v 1 "$OUT"
echo "-> $OUT (${cols}x${rows}, row by row)"
