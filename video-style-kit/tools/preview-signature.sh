#!/bin/sh
# A quick look before committing to a signature: renders a few seconds of a generic swatch
# (the pulse mark + one line of sample text) in each bundled preset, side by side in one
# image, so you compare the actual look instead of picking from text alone. For a from-
# scratch personal signature, run references/signature-wizard.md instead — this is only for
# comparing the bundled presets (or any preset.json you point it at).
#
# Usage (run from $K, the skill folder):
#   tools/preview-signature.sh "<sample line>" [out.png [preset ...]]
# With no presets named, compares every signature/presets/*.json. To filter presets you
# must also name out.png (even the default name) — positional args can't tell "no out.png,
# these presets" apart from "this out.png, no presets" otherwise.
set -eu
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TXT="${1:?Usage: preview-signature.sh \"<sample line>\" [out.png] [preset ...]}"
OUT="${2:-signature-preview.png}"
shift; [ $# -gt 0 ] && shift || true

if [ $# -gt 0 ]; then PRESETS="$*"; else PRESETS="$(cd "$HERE/signature/presets" && ls *.json | sed 's/\.json$//')"; fi

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
PATHS=""; LABELS=""
for name in $PRESETS; do
  f="$HERE/signature/presets/$name.json"
  [ -f "$f" ] || { echo "No preset file at $f" >&2; exit 1; }
  html="$W/$name.html"
  python3 - "$HERE/tools/preview-signature.html" "$html" "$f" "$TXT" <<'PY'
import json, sys
tpl_path, out_path, preset_path, text = sys.argv[1:5]
p = json.load(open(preset_path))
tpl = open(tpl_path).read()
subs = {
    '{{GROUND}}': p.get('groundColorToken', '#111111'),
    '{{INK}}': p.get('inkColorToken', '#f5f5f5'),
    '{{ACCENT}}': p['accentColorToken'],
    '{{NAME}}': p['name'],
    '{{TEXT}}': text,
    '{{SIZE}}': str(p['pulse']['sizePctOfFrameHeight']),
    '{{INSET}}': str(p['pulse'].get('insetPct', 0)),
    '{{DUR}}': '2',
}
for k, v in subs.items():
    tpl = tpl.replace(k, v)
open(out_path, 'w').write(tpl)
PY
  label="$(jq -r '.name' "$f")"
  PATHS="$PATHS $html"
  LABELS="${LABELS:+$LABELS,}$label"
done

npx hyperframes compare $PATHS --at=1.1 --labels="$LABELS" --cols=3 --out="$OUT"
echo "-> $OUT ($LABELS)"
