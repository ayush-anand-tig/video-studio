#!/bin/sh
# Tells a current render from a stale one: hashes what the picture is built from, so a video
# rendered before the latest beats.json/src/ edit fails QC instead of silently shipping.
#
# Usage (run from projects/<slug>/):
#   fingerprint.sh               print the fingerprint of the current sources
#   fingerprint.sh check <mp4>   compare it with the one stamped into <mp4>
#
# Sources: beats.json, every file under src/, and audio/vo.wav (the clock the picture is
# timed to). Phase 2 writes the fingerprint to exports/render.fp in the same command as the
# render; every export stamps that value into the MP4 as comment="fp=<value>".
# check exits 0 (OK), 1 (STALE) or 2 (UNSTAMPED: a video this pipeline didn't export).
set -eu

fp() {
  [ -f beats.json ] && [ -d src ] || { echo "Run from projects/<slug>/ (needs beats.json and src/)." >&2; exit 1; }
  { echo beats.json; [ -f audio/vo.wav ] && echo audio/vo.wav; find src -type f ! -name .DS_Store; } \
    | LC_ALL=C sort | tr '\n' '\0' | xargs -0 shasum -a 256 | shasum -a 256 | cut -c1-16
}

case "${1:-}" in
  "") fp ;;
  check)
    F="${2:?Usage: fingerprint.sh check <mp4>}"
    [ -f "$F" ] || { echo "No such file: $F" >&2; exit 1; }
    stamped=$(ffprobe -v error -show_entries format_tags=comment -of default=nw=1:nk=1 "$F" | sed -n 's/^fp=//p')
    now=$(fp)
    if [ -z "$stamped" ]; then
      echo "UNSTAMPED: $F carries no fingerprint. Fine for a video made elsewhere; otherwise re-export it."
      exit 2
    elif [ "$stamped" = "$now" ]; then
      echo "OK: $F was rendered from the current sources ($now)."
    else
      echo "STALE: $F was rendered from $stamped; sources are now $now."
      echo "beats.json, src/ or audio/vo.wav changed after that render. Re-render, re-export, re-run QC."
      exit 1
    fi
    ;;
  *) echo "Usage: fingerprint.sh [check <mp4>]" >&2; exit 1 ;;
esac
