#!/bin/sh
# Resolves signature/source.env into an actual file at signature/resolved.json.
# Run this once before step 4 (Build) if source.env changed since the last render.
set -eu
HERE="$(cd "$(dirname "$0")/../signature" && pwd)"
. "$HERE/source.env"
OUT="$HERE/resolved.json"

case "${SIGNATURE_SOURCE:-default}" in
  default)
    cp "$HERE/presets/halo.json" "$OUT"
    echo "resolved: default (halo preset — see presets/ for signal/scanline alternates) -> $OUT"
    ;;
  preset:*)
    name="${SIGNATURE_SOURCE#preset:}"
    [ -f "$HERE/presets/$name.json" ] || { echo "No bundled preset named '$name'. Options: $(ls "$HERE/presets" | sed 's/\.json$//' | tr '\n' ' ')" >&2; exit 1; }
    cp "$HERE/presets/$name.json" "$OUT"
    echo "resolved: preset ($name) -> $OUT"
    ;;
  local:*)
    path="${SIGNATURE_SOURCE#local:}"
    [ -f "$path" ] || { echo "No file at $path" >&2; exit 1; }
    cp "$path" "$OUT"
    echo "resolved: local ($path) -> $OUT"
    ;;
  github:*)
    rest="${SIGNATURE_SOURCE#github:}"
    repo_and_ref="${rest%%:*}"
    filepath="${rest#*:}"
    repo="${repo_and_ref%%@*}"
    if [ "$repo_and_ref" != "$repo" ]; then ref="${repo_and_ref#*@}"; else ref="main"; fi
    url="https://raw.githubusercontent.com/$repo/$ref/$filepath"
    curl -fsSL "$url" -o "$OUT" || { echo "Couldn't fetch $url — check the repo/ref/path, or that it's public." >&2; exit 1; }
    echo "resolved: github ($repo@$ref:$filepath) -> $OUT"
    ;;
  url:*)
    url="${SIGNATURE_SOURCE#url:}"
    curl -fsSL "$url" -o "$OUT" || { echo "Couldn't fetch $url" >&2; exit 1; }
    echo "resolved: url -> $OUT"
    ;;
  *)
    echo "Unrecognized SIGNATURE_SOURCE: ${SIGNATURE_SOURCE:-}" >&2
    exit 1
    ;;
esac

command -v jq >/dev/null 2>&1 && jq empty "$OUT" || python3 -c "import json,sys; json.load(open('$OUT'))" 2>/dev/null \
  || { echo "Warning: $OUT doesn't look like valid JSON" >&2; exit 1; }
